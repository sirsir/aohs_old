module UpdateCurrentComputer
  
  class UpdateCurrentComputerStatus
    
    def self.update
      clear_all
      comps = ComputerLog.select("remote_ip, MAX(check_time) AS last_check_time").group("remote_ip").all
      okeys = CurrentComputerStatus.new.attributes.to_h.keys
      comps.each do |comp|
        cl = ComputerLog.where(["remote_ip = ? AND check_time >= ?",comp.remote_ip ,comp.last_check_time]).first
        unless cl.nil?
          ccs = CurrentComputerStatus.new(cl.attributes.to_h.select { |k,v| okeys.include?(k) })
          ccs.save!
        end
      end
    end
    
    def self.clear_all
      CurrentComputerStatus.delete_all
    end
    
    # end class
  end
  
  
  class UpdateUserExtension
    
    LAST_NDAYS_ATL = 3
    LAST_NDAYS_COMPLOG = 5
    
    # mapping telephone numbers
    # 1. fixed extension
    # 2. fixed by autocall <aeon>
    # 3. detected by client ip andd login <watcher>
    #
    
    def self.init_info
      log "trying to create fixed number mapping."
      exts = Extension.specific_user.all
      exts.each do |ext|
        phn = Extension.joins("LEFT JOIN dids ON dids.extension_id = extensions.id").select("extensions.number AS ext, dids.number AS did").where(number: ext.number).all
        phn.each do |ph|
          uem = {
            extension: ph.ext,
            did: ph.did,
            agent_id: ext.user_id
          }
          begin
            log " adding: #{uem.inspect}"
            UserExtensionMap.create_or_update(uem)
          rescue => e
            log " error: #{e.message}"
          end
        end
      end
    end
    
    def self.update_follow_atl
      log "trying to update mappings from autocall master data."
      
      ldate = Date.today - LAST_NDAYS_ATL.days
      
      sql = []
      sql << "SELECT u.id,u.login,a.operator_id,a.extension"
      sql << "FROM users u JOIN user_atl_attrs a ON u.id = a.user_id AND a.flag <> 'D'"
      sql << "WHERE u.state <> 'D'"
      sql << "AND a.updated_at >= '#{ldate.strftime("%Y-%m-%d")} 00:00:00'"
      sql << "GROUP BY u.id, a.extension"
      sql << "ORDER BY a.extension"
      sql = sql.join(" ")
      
      results = ActiveRecord::Base.connection.select_all(sql)
      results.each do |rs|
        did = x_to_number(rs["extension"])
        did = nil if did.length <= 8
        ext = x_to_extension(x_to_number(rs["extension"]))
        ext = nil if ext.length > 8
        next if did.blank? and ext.blank?
        
        # valid number
        unless ext.blank?
          t_exts = [ext]
          t_exts.concat(['0','5','7'].map { |x| "#{x}#{ext}"})
          t_ext = Extension.where(number: t_exts).order(id: :desc).first
          unless t_ext.nil?
            ext = t_ext.number
          else
            ext = nil
          end
        end
        unless did.blank?
          t_dids = [did]
          t_did = Did.where(number: t_dids).order(id: :desc).first
          unless t_did.nil?
            did = t_did.number
          else
            did = nil
          end
        end
        next if did.blank? and ext.blank?
        
        uem = {
          agent_id: rs["id"],
          extension: ext,
          did: did
        }
        begin
          log " adding: #{uem.inspect}"
          UserExtensionMap.create_or_update(uem)
        rescue => e
          log " error: #{e.message}"
        end
      end
      
    end
        
    def self.update
      
      log "trying to update from computer status."
      
      ccs = CurrentComputerStatus.ndays_ago(LAST_NDAYS_COMPLOG).all
      ccs.each do |cs|
        # check computer 
        cif = ComputerInfo.where(ip_address: cs.remote_ip).first
        if cif.nil?
          cif = ComputerInfo.where(computer_name: cs.computer_name).first
        end
        next if cif.nil?
        # check user
        usr = User.not_deleted.where(login: cs.login_name).first
        next if usr.nil?
        # check numbers
        phn = Extension.joins("LEFT JOIN dids ON dids.extension_id = extensions.id").select("extensions.number AS ext, dids.number AS did").where(id: cif.extension_id).all
        phn.each do |ph|
          uem = {
            extension: ph.ext,
            did: ph.did,
            agent_id: usr.id
          }
          if cs.computer_logoff?
            log " removing: #{uem.inspect}"
            UserExtensionMap.remove_mapping(uem)
          else
            begin
              log " adding: #{uem.inspect}"
              UserExtensionMap.create_or_update(uem)
            rescue => e
              log " error: #{e.message}"
            end
          end
        end
      end
      
    end
    
    def self.clear_all
      UserExtensionMap.delete_all
    end
    
    private

    def self.x_to_number(n)
      return n.to_s.scan(/\d/).join.chomp.strip
    end
    
    def self.x_to_extension(n)
      # format
      # 99999
      # XXX99999
      if n.length <= 5
        return n
      end
      if n.length <= 8
        txt = /^(\d{3})(\d{4,5})$/.match(n)
        unless txt.nil?
          return txt[2]
        end
      end
      return n
    end
    
    def self.log(msg)
      Rails.logger.info "(extension-mapping) #{msg}"
    end
    
  end
  
  def self.update_all
    UpdateCurrentComputerStatus.update
    UpdateUserExtension.update
  end
  
  def self.init_ext
    UpdateUserExtension.init_info
    UpdateUserExtension.update_follow_atl
  end
  
end