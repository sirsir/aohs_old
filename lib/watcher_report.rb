class WatcherReport
  
  def initialize(log_date=Date.today)
    @date = log_date.nil? ? Date.today : log_date
  end

  def result
    
    @result = extension_result
    @vcount = voice_log_counts
    @users  = users_info
    @logs   = unknown_logs
    
    @result.each do |r|
      
      r['users'] = ""
      r['result_class'] = ""
      r['remarks'] = []
      
      unless r['agent_id'].blank?
        r['agent_id'].to_s.split(",").each do |uid|
          if @users[uid.to_s].nil?
            r['users'] << "##{uid}"
            r['remarks'] << "No user"
          else
            r['users'] << @users[uid.to_s]
          end
        end
      else
        r['result_class'] = "danger"
      end
      
      # check missing
      x = -1
      @logs.each_with_index do |l,i|
        if (l['remote_ip'] == r['ip_address']) or (l['computer_name'] == r['computer_name'])
          x = i
          if r['users'].to_s.length <= 0
            if @users[l['login_name'].to_s.downcase].nil?
              r['users'] << l['login_name']
              r['remarks'] << "No user"
            else
              r['users'] << @users[l['login_name'].to_s.downcase]
            end
          end
          unless l['remote_ip'] == r['ip_address']
            r['remarks'] << "Wrong IP"  
          end
          unless l['computer_name'] == r['computer_name']
            r['remarks'] << "Wrong Computer Name" 
          end
          if r['logdate'].nil? and (not l['logdate'].nil?) 
            r['logdate'] = l['logdate']
          end
          break
        end
      end
      @logs.delete_at(x) if x >= 0
      r['call_count'] = @vcount[r['number']].to_i unless @vcount[r['number']].nil?
      if r['call_count'].to_i > 0
        r['mapped_count'] = @vcount[r['number'] + "_ok"].to_i
        if r['agent_id'].blank?
          r['result_class'] = 'warning'
        else
          r['result_class'] = 'success'
        end
      else
        r['result_class'] = 'warning' unless r['result_class'] == 'danger'
      end
      begin
        r['logdate'] = r['logdate'].to_formatted_s(:web) unless r['logdate'].blank?
      rescue
      end
    end
    
    unless @logs.empty?
      @logs.each do |l|
        h = Hash.new
        h["ip_address"] = l['remote_ip']
        h["computer_name"] = l['computer_name']
        h["users"] = l['login_name']
        h["result_class"] = 'missing'
        @result.concat([h])
      end
    end
    
    return @result
  
  end
  
  private
  
  def extension_result
    sql =  "SELECT e.number, c.computer_name, c.ip_address, t.code_name AS location_name, s1.dids, s1.agent_id, s1.logdate "
    sql << "FROM extensions e "
    sql << "LEFT JOIN computer_infos c ON e.id = c.extension_id "
    sql << "LEFT JOIN location_infos t ON t.id = e.location_id "
    sql << "LEFT JOIN ( "
    sql << "SELECT extension, GROUP_CONCAT(did) AS dids, GROUP_CONCAT(DISTINCT agent_id) AS agent_id "
    unless @date == Date.today
      sql << ", MAX(log_date) AS logdate "
      sql << "FROM user_extension_logs "
      sql << "WHERE log_date BETWEEN '#{@date} 00:00:00' AND '#{@date} 23:59:59' "
    else
      sql << ", MAX(updated_at) AS logdate "
      sql << "FROM user_extension_maps "
      sql << "WHERE updated_at BETWEEN '#{@date} 00:00:00' AND '#{@date} 23:59:59' "
    end
    sql << "GROUP BY extension) s1 " 
    sql << "ON e.number = s1.extension "
    sql << "ORDER BY t.code_name, e.number "
    return ActiveRecord::Base.connection.select_all(sql).to_a
  end
  
  def unknown_logs
    sql =  "SELECT remote_ip, computer_name, login_name, MAX(check_time) AS logdate "
    sql << "FROM computer_logs "
    sql << "WHERE check_time BETWEEN '#{@date} 00:00:00' AND '#{@date} 23:59:59' "
    sql << "GROUP BY login_name,remote_ip"
    return ActiveRecord::Base.connection.select_all(sql).to_a
  end
  
  def voice_log_counts
    vcounts = VoiceLog.select("extension, COUNT(0) AS call_count, SUM(IF(agent_id>0,1,0)) AS mapped_count").at_date(@date).group(:extension).order(false).all
    ret = {}
    vcounts.each do |v|
      ret[v.extension.to_s] = v.call_count.to_i
      ret[v.extension.to_s + "_ok"] = v.mapped_count
    end
    vcounts = nil
    return ret
  end
  
  def users_info
    users = User.only_active.select([:id,:login]).all
    ret = {}
    users.each do |u|
      ret[u.id.to_s] = "#{u.login} (##{u.id})"
      ret[u.login.to_s.downcase] = "#{u.login} (##{u.id})"
    end
    return ret
  end

end