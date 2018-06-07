module AppUtils  
  class InitialDb
    
    def self.reset_autoincrement_id
      #log "=> Reset autoincrement id"
      #max_id = VoiceLogToday.maximum(:id).to_i
      #if max_id < 100000
      #  ActiveRecord::Base.connection.execute("ALTER TABLE voice_logs_today AUTO_INCREMENT = 100000")  
      #end
      #[User, Group, Customer, Extension].each do |md|
      #  max_id = md.maximum(:id).to_i
      # if max_id < 100
      #   ActiveRecord::Base.connection.execute("ALTER TABLE #{md.table_name} AUTO_INCREMENT = 100")  
      # end
      #end
    end
    
    def self.update_max_voice_log_id
      max_id_1 = VoiceLogToday.maximum(:id).to_i
      max_id_2 = VoiceLog.maximum(:id).to_i
      max_id = 100000
      max_id = max_id_1 if max_id_1 > max_id
      max_id = max_id_2 if max_id_2 > max_id
      if max_id > 0
        log "=> Updating autoincrement id to #{max_id}"
        ActiveRecord::Base.connection.execute("ALTER TABLE #{VoiceLogToday.table_name} AUTO_INCREMENT = #{max_id+1}")  
      end
    end
    
    def self.update_constants
      
      #
      # get list from source file and update to table system_consts
      # 
      
      log "=> Updating application data"
      
      consts_list.each do |ux|
        recs = load_data(ux[:target])
        next if recs.nil?
        log "-> try updating ... #{ux[:target]},#{ux[:cate]}"
        recs.each do |rec|
          insert_or_update_const(ux[:cate], rec)
        end
        if ux[:cleanup] == true
          log "-> cleaning list"
          cleanup_constants(ux[:cate],recs)
        end
      end
      
    end
    
    def self.update_roles
      
      #
      # initial system roles (default) 
      #
      
      log "=> Updating role of user"
      
      recs = load_data("roles")
      recs.each do |rec|
        insert_or_update_role(rec)
      end
      
    end
    
    def self.update_privileges
      
      #
      # initial and update system privilges
      #
      
      log "=> Updating privileges"
      
      recs = load_data("privileges.json")
      recs = recs["aohs"]
      recs.each do |rec|
        rec["events"].each do |event|
          begin
            insert_or_update_privilege(rec, event)
          rescue => e
            STDERR.puts e.message
          end
        end
      end
      
      cleanup_privileges
    
    end
    
    def self.update_admin_permission
      log "=> Updating all permissions for admin"
      admin_roles = Role.where(name: ROLE_ADMIN_GROUP.first).all
      admin_roles.each do |role|
        allow_permission_to(role)
      end
    end
    
    def self.update_groups
      log "=> Updating groups"
      recs = load_data("groups")
      unless recs.nil?
        recs.each do |rec|
          insert_or_update_group(rec)
        end
        Group.repair_and_update_sequence_no
      end
    end
    
    def self.update_users
      log "=> Updating default users"
      recs = load_data("users")
      unless recs.nil?
        recs.each do |rec|
          begin
            insert_or_update_user(rec)
          rescue => e
            STDERR.puts e.message
          end
        end
      end
    end
    
    def self.update_configurations
      log "=> Updating configurations"
      confs = load_data("configurations")
      confs.each_key do |config_name|
        config_list = confs[config_name]
        cg = create_or_update_conf_group(config_name)
        unless config_list.empty?
          config_list.each do |cf|
            create_or_update_conf(cg, cf)
          end
        end
      end
    end
    
    def self.update_display_column_tbls
      log "=> Updating display tables"
      data = load_data("display_columns.json")
      upd_tables = []
      data.each do |tbl, cols|
        updated_col = []
        upd_tables << tbl
        cols.each_with_index do |col,i|
          c = DisplayColumnTable.where({ table_name: tbl, variable_name: col["variable"] }).first
          if c.nil?
            c = DisplayColumnTable.new({ table_name: tbl })
          end
          c.column_name = col["title"]
          c.column_type = col["type"]
          c.variable_name = col["variable"]
          c.sortable = (col["sortable"] ? "Y" : "N")
          if c.searchable.blank?
            c.searchable = (col["searchable"] ? "Y" : "N")
          end
          if c.order_no.to_i <= 0
            c.order_no = (i+1) * 10
          end
          if col["visible"] == false
            c.invisible
          else
            c.visible
          end
          
          c.save
          updated_col << c.id
        end
        DisplayColumnTable.where({ table_name: tbl }).where.not(id: updated_col).delete_all
      end
      
      # remove unused tables 
      unless upd_tables.empty?
        DisplayColumnTable.where.not(table_name: upd_tables).delete_all
      end
    end
    
    private
    
    def self.log(msg)
      STDOUT.puts msg
    end
    
    def self.load_data(data_name)
      # to load master data from source file.
      # source directory
      data_dir = File.join(Rails.root, "lib", "data")
      # source file
      fnames = [File.join(data_dir, data_name), File.join(data_dir, "defaults.json")]
      while not fnames.empty?
        fname = fnames.shift
        if File.exists?(fname)
          log "=> Loading source file: #{File.basename(fname)}"
          json_data = JSON.parse(File.read(fname))
          if File.basename(fname,".*") == "defaults"
            return json_data[data_name]
          else
            return json_data
          end
        end
      end
      # no data source
      return nil
    end
  
    def self.insert_or_update_const(cate,rec)
      
      #
      # insert or update constanst to table system_const
      #
      
      cond = {
        cate: cate,
        code: rec["code"]
      }
      rx = SystemConst.where(cond).first
      if rx.nil?
        attrs = {
          cate: cate,
          code: rec["code"],
          name: rec["name"]
        }
        rx = SystemConst.new(attrs)
        rx.save!
      else
        rx.name = rec["name"]
        rx.save!
      end
    end
    
    def self.cleanup_constants(cate,recs)
      codes = recs.map { |c| c["code"] }
      SystemConst.where({ cate: cate }).where.not(code: codes).delete_all
    end
    
    def self.consts_list
      
      #
      # list of constants data for system
      #
      
      return [
        { cate: ":sex", target: "sexs", cleanup: true },
        { cate: ":ustate", target: "user-states", cleanup: true },
        { cate: ":log-types", target: "log-types", cleanup: true },
        { cate: ":log-events", target: "log-events", cleanup: true },
        { cate: ":file-types", target: "file-types" },
        { cate: "keyword_type", target: "keyword_type", cleanup: true },
        { cate: "call-type", target: "call-type" },
        { cate: "name-title", target: "name-title", cleanup: true },
        { cate: "edu-degree", target: "edu-degree" },
        { cate: "speaker_type", target: "speaker_type", cleanup: true },
        { cate: "call_direction", target: "call_direction" },
        { cate: "landing-page", target: "landing-page", cleanup: true },
        { cate: "group_types", target: "group_types" },
        { cate: "notify_level", target: "notify_level", cleanup: true },
        { cate: "delinquent", target: "delinquent", cleanup: true }
      ]
    
    end
    
    def self.insert_or_update_role(rec)
      attrs = {
        name: rec["name"]
      }
      role = Role.where(attrs).first
      if role.nil?
        attrs = {
          name: rec["name"],
          priority_no: rec["pri"].to_i,
          level: rec["flag"].to_s
        }
        role = Role.new(attrs)
      end
      role.flag = rec["flag"] if rec.has_key?("flag")
      role.save!
    end
    
    def self.insert_or_update_privilege(rec, event)
      # initial
      @update_privileges = [] unless defined? @update_privileges
      @pv_order_no = 0 unless defined? @pv_order_no
      unless @pv_prev_catemod == rec["module"]
        @pv_order_no += 1
        @pv_prev_catemod = rec["module"]
      end
      
      unless event["customer"].blank?
        if Settings.site.codename == "amivoice"
          # nothing
        else
          custs = event["customer"].split(",").map { |c| c.strip }
          unless custs.include?(Settings.site.codename)
            return false
          end
        end
      end
      
      order_no = [sprintf("%04d", @pv_order_no)]
      event["no"].to_s.split(".").each do |n|
        order_no << sprintf("%02d",n.to_i)
      end
      
      cond = {
        module_name: rec["module"], event_name: event["name"]
      }
      unless event["link"].blank?
        cond[:link_name] = event["link"].to_s
      end
      
      rx = Privilege.where(cond).first
      if rx.nil?
        rx = Privilege.new
      end
      
      rx.module_name = rec["module"]
      rx.event_name = event["name"]
      rx.link_name = event["link"].to_s
      rx.description = event["title"]
      rx.category = rec["category"]
      rx.order_no = order_no.join(".")
      rx.section = "aohs"
      rx.save
      @update_privileges << rx.id
    end
    
    def self.cleanup_privileges
      unless @update_privileges.empty?
        if Privilege.where.not(id: @update_privileges).count > 0
          Privilege.where.not(id: @update_privileges).delete_all
          Permission.where.not(privilege_id: @update_privileges).delete_all
        end
      end
    end
    
    def self.insert_or_update_group(rec)
      attrs = {
        name: rec["name"]
      }
      group = Group.where(attrs).first
      if group.nil?
        attrs = {
          name: rec["name"],
          short_name: rec["short_name"]
        }
        group = Group.new(attrs)
        group.do_locked
        group.save!
      end
    end
    
    def self.allow_permission_to(role)
      permissions = Permission.where(role_id: role.id).all
      unless permissions.empty?
        permissions.delete_all
      end
      privileges = Privilege.all
      privileges.each do |priv|
        attrs = {
          role_id: role.id,
          privilege_id: priv.id
        }
        px = Permission.new(attrs)
        px.save!
      end
    end
  
    def self.insert_or_update_user(rec)
       
      role  = Role.where(name: rec["role"]).first
      group = Group.where(name: rec["group"]).first
      
      if not role.nil? and not group.nil?
        usr = User.where(login: rec["username"]).first
        if usr.nil?
          attrs = {
            login: rec["username"],
            employee_id: rec["employee_id"],
            full_name_en: rec["full_name"],
            role_id: role.id
          }
          usr = User.new(attrs)
          usr.flag = DB_LOCKED_FLAG
          usr.reset_default_password
        end
        
        usr.do_active
        usr.save!      
        
        gm = GroupMember.only_member.where(user_id: usr.id).first
        if gm.nil?
          attrs = {
            user_id: usr.id,
            group_id: group.id,
          }
          gm = GroupMember.new(attrs)
        else
          gm.group_id = group.id
        end
        gm.set_as_member
        gm.save!
        
      end
      
    end
  
    def self.create_or_update_conf_group(config_name)
      cg = ConfigurationGroup.where({name: config_name}).first
      if cg.nil?
        cg = ConfigurationGroup.new({name: config_name})
        cg.save
      end
      return cg
    end
    
    def self.create_or_update_conf(cg,cf)
      
      cond = {
        configuration_group_id: cg.id,
        variable: cf["name"]
      }
      cnf = Configuration.where(cond).first
      
      if cnf.nil?
        attrs = {
          variable: cf["name"],
          desc: cf["desc"],
          value_type: cf["type"],
          configuration_group_id: cg.id
        }
        cnf = Configuration.new(attrs)
        cnf.save!
      end
      
      cond = {
        node_id: 0,
        node_type: "default",
        configuration_group_id: cg.id
      }
      cft = ConfigurationTree.where(cond).first
      if cft.nil?
        attrs = cond
        cft   = ConfigurationTree.new(attrs)
        cft.save!
      end
      
      cond = {
        configuration_id: cnf.id,
        configuration_tree_id: cft.id
      }
      cfd = ConfigurationDetail.where(cond).first
      if cfd.nil?
        attrs = {
          configuration_id: cnf.id,
          configuration_tree_id: cft.id,
          conf_value: cf["default"]
        }
        cfd = ConfigurationDetail.new(attrs)
        cfd.save!
      else
        cfd.conf_value = cf["default"]
        cfd.save
      end
    
    end
  
  end # end class
  
  def self.initial_db
    InitialDb.reset_autoincrement_id
    InitialDb.update_constants 
    InitialDb.update_configurations
    InitialDb.update_roles
    InitialDb.update_groups
    InitialDb.update_users
    InitialDb.update_privileges
    InitialDb.update_admin_permission
    InitialDb.update_display_column_tbls
  end
  
end