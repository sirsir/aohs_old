require 'csv'
require 'yaml'

module DataSyncer
  module Aeon
    
    class AtlUserSyncer
      
      MS_GRADES = [
        "A","A+","A-",
        "B","B+","B-",
        "C","C+","C-",
        "D","D+","D-",
        "E","E+","E-",
        "F","F+","F-",
        "N"
      ]
      
      #
      # this class used for only sync user data between
      # autocall and aohs system (from auto call)
      # that will be update automatically using cron
      #
      
      include SysLogger::ScriptLogger
      
      def self.sync(options)
        as = new(options)
        as.perform_sync
        as.remove_inactive_records
      end
      
      def self.download_result
        
      end
      
      def initialize(options)
        set_logger_path "aeonatl/syncuser.log"
        
        @ndata = []
        @odata = []
        @stime = Time.now
        
        @atl_regions = {}
        @atl_roles = {}
        @atl_teams = {}
        @atl_duty = {}
        @atl_perfgroup = {}
        @atl_sections = {}
        
        @counter = { total: 0, added: 0, updated: 0, error: 0, skip: 0 }
      end
      
      def perform_sync
        logger.info "--"
        logger.info "trying to syncronize users data."
        
        # download source file and load to array
        
        src_files = get_source_file
        src_files.each do |src_file|
          load_data_from_file(src_file)
          src_file[:outpath] = rename_source_file(src_file[:outpath])
        end
        
        unless @ndata.empty?
          # prepare and validate
          load_cache_data
          get_old_users
          recheck_rows_data
          display_minfo
          # update
          update_meta_list
          update_users
          write_cache_data
          export_update_result
        end
        
        logger.info "summary: total=#{@counter[:total]}, added=#{@counter[:added]}, updated=#{@counter[:updated]}, skip=#{@counter[:skip]}, error=#{@counter[:error]}, time=#{(Time.new-@stime).round(5)}secs"
        logger.info "sync data done"
      end
      
      def remove_inactive_records
        n_days = 30
        sql = []
        sql << "SELECT * FROM ("
        sql << "SELECT u.id,u.full_name_en,MAX(u.updated_at) AS lastudate,MAX(a.updated_at) AS lstdate, DATEDIFF(NOW(),MAX(a.updated_at)) AS ndays FROM users u JOIN user_atl_attrs a"
        sql << "ON u.id = a.user_id"
        sql << "WHERE a.flag <> 'D' AND u.state <> 'D'"
        sql << "GROUP BY u.id ) x"
        sql << "WHERE x.ndays > 0"
        sql = sql.join(" ")
        found_users = ActiveRecord::Base.connection.select_all(sql)
        logger.info "trying to delete inactive user, found #{found_users.length} records"
        unless found_users.empty?
          found_users.each do |u|
            xdays = u["ndays"].to_i
            next if xdays >= n_days
            begin
              usr = User.where(id: u["id"]).first
              unless usr.nil?
                if usr.do_delete
                  usr.save
                  logger.info "deleted user id #{u["id"]}"
                end
              end
            rescue => e
              logger.info "failed to delete user id #{u["id"]}"
            end
          end
        end
      end
      
      private
      
      def recheck_rows_data
        @ndata.each_with_index do |row,i|
          @ndata[i] = recheck_row_data(row)
        end
        recheck_loginname
        row_data_grouping
      end
      
      def row_data_grouping
        logger.info "trying to sort data for checking"
        @ndata = @ndata.sort_by { |item| [item[:citizen_id], item[:dummy], item[:operator_id]] }
        
        logger.info "checking dupplicate data"
        @ndata.each_with_index do |r1, i|
          next if r1[:skipupdate] == true 
          found_dup = false
          drowno = []
          dteams = []
          dteamnms = []
          ddeln = []
          dopers = []
          dpgroups = []
          dpgroupnms = []
          demp = []
          dcit = []
          dnames = []
          dsections = []
          dsectionns = []
          ddummy = []
          dgrades = []
          @ndata.each_with_index do |r2, j|
            next if i == j
            next if r2[:skipupdate] == true
            dup_reasons = []
            if (r1[:employee_id] == r2[:employee_id]) and (r1[:citizen_id] == r2[:citizen_id])
              r2[:skipupdate] = true
              dup_reasons << "dup employee-id and citizen-id"
            elsif (r1[:employee_id] == r2[:employee_id]) and (r1[:full_name_th] == r2[:full_name_th])
              r2[:skipupdate] = true
              dup_reasons << "dup employee-id and name"
            elsif (r1[:citizen_id] == r2[:citizen_id])
              r2[:skipupdate] = true
              dup_reasons << "dup citizen-id"
            end
            if r2[:skipupdate] == true
              dnames << r2[:full_name_en]
              dcit << r2[:citizen_id]
              demp << r2[:employee_id]
              drowno << r2[:row_no]
              dteams << r2[:team_id]
              dteamnms << r2[:team_name]
              ddeln << r2[:delinquent]
              dopers << r2[:operator_id]
              dpgroups << r2[:performance_group_id]
              dpgroupnms << r2[:performace_group_name]
              dsections << r2[:section_id]
              dsectionns << r2[:section_name]
              ddummy << r2[:dummy]
              dgrades << r2[:grade]
              found_dup = true
              r2[:skip_reasons] = dup_reasons.uniq
            end
          end
          if found_dup
            logger.info "duplicate at #{r1[:row_no]} - #{drowno.join("|")}"
            logger.info "      name_en = #{r1[:full_name_en]} - #{dnames.join("|")}"
            logger.info "   citizen_id = #{r1[:citizen_id]} - #{dcit.join("|")}"
            logger.info "  employee_id = #{r1[:employee_id]} - #{demp.join("|")}"
            logger.info "  operator_id = #{r1[:operator_id]} - #{dopers.join("|")}"
            logger.info "         team = #{r1[:team_id]} - #{dteams.join("|")}"
            logger.info "   perf-group = #{r1[:performance_group_id]} - #{dpgroups.join("|")}"
            logger.info "      section = #{r1[:section_id]} - #{dsections.join("|")}"
            logger.info "         deln = #{r1[:delinquent]} - #{ddeln.join("|")}"
            @ndata[i][:attrs] = []
            drowno.each_with_index do |r0,k|
              @ndata[i][:attrs] << {
                operator_id: dopers[k],
                team_id: dteams[k],
                team_name: dteamnms[k],
                performance_group_id: dpgroups[k],
                performance_group_name: dpgroupnms[k],
                section_id: dsections[k],
                section_name: dsectionns[k],
                dummy: ddummy[k],
                grade: dgrades[k],
                delinquent: ddeln[k]
              }
            end
          end
        end
      end
      
      def write_cache_data
        cache_file = File.join(Rails.root,'tmp','synuser.cache')
        cdata = {
          regions: @atl_regions,
          roles: @atl_roles,
          teams: @atl_teams,
          duty: @atl_duty,
          sections: @atl_sections
        }
        logger.info "Updating cache file #{cache_file}"
        File.open(cache_file, 'w') { |f| f.write(YAML.dump(cdata)) }
      end
      
      def load_cache_data
        cache_file = File.join(Rails.root,'tmp','synuser.cache')
        if File.exists?(cache_file)
          logger.info "Loading cache data #{cache_file}"
          cdata = YAML.load(File.read(cache_file))
          unless cdata[:regions].nil?
            @atl_regions = @atl_regions.merge(cdata[:regions])
          end
          unless cdata[:roles].nil?
            @atl_roles = @atl_roles.merge(cdata[:roles])
          end
          unless cdata[:teams].nil?
            @atl_teams = @atl_teams.merge(cdata[:teams])
          end
          unless cdata[:duty].nil?
            @atl_duty = @atl_duty.merge(cdata[:duty])
          end
          unless cdata[:perfgroup].nil?
            @atl_perfgroup = @atl_perfgroup.merge(cdata[:perfgroup])
          end
          unless cdata[:sections].nil?
            @atl_sections = @atl_sections.merge(cdata[:sections])
          end
        end
      end
      
      def update_meta_list
        # regions
        begin
          list = @atl_regions.to_a.map { |x|
            xa = x[1]
            { code: xa[:org_id], name: xa[:name] }  
          }
          SystemConst.update_list("atl-regions", list)
        rescue => e
          logger.error "error update list regions, #{e.message}"
        end
        # teams
        begin
          list = @atl_teams.to_a.map { |x|
            xa = x[1]
            { code: xa[:org_id], name: xa[:name] }  
          }
          SystemConst.update_list("atl-teams", list)
        rescue => e
          logger.error "error update list teams, #{e.message}"
        end
        # performance group
        begin
          list = @atl_perfgroup.to_a.map { |x|
            xa = x[1]
            { code: xa[:org_id], name: xa[:name] }  
          }
          SystemConst.update_list("atl-perfgroups", list)
        rescue => e
          logger.error "error update list perf-groups, #{e.message}"
        end
        # roles
        begin
          list = @atl_roles.to_a.map { |x|
            xa = x[1]
            { code: xa[:org_id], name: xa[:name] }  
          }
          SystemConst.update_list("atl-roles", list)
        rescue => e
          logger.error "error update list roles, #{e.message}"
        end
        # sections
        begin
          list = @atl_sections.to_a.map { |x|
            xa = x[1]
            { code: xa[:org_id], name: xa[:name] }  
          }
          SystemConst.update_list("atl-sections", list)
        rescue => e
          logger.error "error update list sections, #{e.message}"
        end
      end
      
      def display_minfo
        [@atl_regions,@atl_roles,@atl_teams,@atl_duty,@atl_perfgroup,@atl_sections].each do |item|
          next if item.nil?
          logger.info "item count #{item.length}."
          item.each do |k,v|
            logger.info "#{k} - #{v.inspect}"
          end
        end
      end
      
      def load_data_from_file(src_file)
        logger.info "trying to load data from file '#{src_file}'"
        begin
          row_no = 1
          file_enc = "ISO-8859-11:UTF-8"
          input_file = src_file[:outpath]
          CSV.foreach(input_file, headers: false, encoding: file_enc) do |row|
            @ndata << map_row_fields(row, row_no)
            @counter[:total] += 1
            row_no += 1
          end
        rescue => e
          logger.error "error load source file. #{e.message}"
        end
      end
      
      def get_source_file
        logger.info "trying to get source files using SFTP."
        src_files = ["USERMASTER01","USERMASTER02"]
        begin
          sftp = SftpClient.new(config)
          opts = {
            file_patterns: src_files
          }
          sfiles = sftp.get_files(source_path, output_path, opts)
        rescue => e
          sfiles = []
          logger.error "error to get file from SFTP."
          logger.error e.message
        end
        return sfiles 
      end
      
      def map_row_fields(row, row_no)
        nrow = {
          row_no: row_no
        }
        row_a_to_h(row).each do |key, val|
          val = val.to_s.chomp.strip
          val = val.gsub(/\s+/, " ")
          case key.to_s.strip.downcase
          when "national_id", "citizen_id"
            nrow[:citizen_id] = val
          when "operator_code"
            nrow[:operator_id] = val
          when "employee_id"
            nrow[:employee_id] = val
          when "th_name"
            nrow[:full_name_th] = val
          when "en_name"
            nrow[:full_name_en] = val
            nrow[:grade] = get_grade_from_name(val)
            nrow[:dummy] = is_dummy(val)
          when "regoin_id"
            nrow[:region_code] = val
          when "regoin_name"
            nrow[:region_name] = val
          when "delinquent"
            nrow[:delinquent] = deliquent_value_map(val)
          when "role_id"
            nrow[:role_id] = val
          when "role_name"
            nrow[:role_name] = role_name_map(val)
          when "branch_code"
            nrow[:brance_code] = val
          when "ext_no"
            nrow[:extension] = val
          when "performance_group_id"
            nrow[:performance_group_id] = val
          when "performance_group_name"
            nrow[:performance_group_name] = val
          when "section_id"
            nrow[:section_id] = val
          when "section_name"
            nrow[:section_name] = val
          when "duty"
            nrow[:duty] = val
            nrow[:duty2] = duty_name_map(val) 
          when "team_id"
            nrow[:team_id] = val
          when "team_name"
            nrow[:team_name] = val
            # recheck dummy using team's name 
            if nrow[:dummy] == "N" and is_dummy(val)
              nrow[:dummy] = is_dummy(val)
            end
          when "system_id"
            nrow[:system_id] = val
          when "client_id"
            nrow[:client_id] = val
          when "timestamp"
            nrow[:timestamp] = Time.parse(val) 
          end
        end
        
        @atl_regions[nrow[:region_code]] = { name: nrow[:region_name], org_id: nrow[:region_code] } 
        @atl_roles[nrow[:role_id]] = { name: nrow[:role_name], org_id: nrow[:role_id] }
        @atl_teams[nrow[:team_id]] = { name: nrow[:team_name], org_id: nrow[:team_id] }
        @atl_duty[nrow[:duty2]] = { name: nrow[:duty2], org_name: nrow[:duty] }
        @atl_perfgroup[nrow[:performance_group_id]] = { name: nrow[:performance_group_name], org_id: nrow[:performance_group_id] }
        @atl_sections[nrow[:section_id]] = { name: nrow[:section_name], org_id: nrow[:section_id] }
        return nrow
      end
      
      def recheck_row_data(row)
        # name en
        name_en, title_en = name_and_title(row[:full_name_en])
        row[:full_name_en] = name_en
        row[:title_en] = title_en
        row[:login_names] = get_possible_login_names(row[:full_name_en])
        nam = get_firstname_and_lastname(row[:full_name_en])
        row[:first_name_en] = nam[:first]
        row[:last_name_en] = nam[:last]
        
        # name th
        name_th, title_th = name_and_title(row[:full_name_th])
        row[:full_name_th] = name_th
        row[:title_th] = title_th
        nam = get_firstname_and_lastname(row[:full_name_th])
        row[:first_name_th] = nam[:first]
        row[:last_name_th] = nam[:last]
        
        # citizen id
        unless row[:citizen_id].blank?
          row[:citizen_id] = sprintf("%013d", row[:citizen_id])  
        end
        
        # find existing user
        u = get_existing_user(row)
        unless u.nil?
          row[:user_id] = u[:user_id]
          row[:login] = u[:login]
        end
        
        # system role
        r = get_role(row[:duty2])
        unless r.nil?
          row[:sys_role_id] = r.id  
        end
        
        # group / team
        g_id = get_team(row[:team_name], row[:team_id])
        unless g_id.nil?
          row[:sys_group_id] = g_id  
        end
        
        #STDOUT.puts row.inspect
        return row
      end
      
      def recheck_loginname
        m = @ndata.length
        i = 0
        while i < m
          if @ndata[i][:login].nil?
            j = 0
            while j < m
              @ndata[i][:login_names].each do |login|
                if @ndata[j][:login_names].include?(login)
                  @ndata[i][:login_names].delete(login)
                end
              end
              j += 1
            end
            unless @ndata[i][:login_names].empty?
              pos_names = find_login_from_computerlog(@ndata[i][:login_names])
              if pos_names.empty?
                @ndata[i][:login] = @ndata[i][:login_names].first
              else
                @ndata[i][:login] = pos_names.first
              end
            end
          end
          i += 1
        end
      end
      
      def get_existing_user(row)
        matched = []
        @odata.each do |u|
          mcount = 0
          # match at lease 2 key to check 
          [:employee_id, :full_name_th, :first_name_th, :first_name_en, :last_name_en, :last_name_th, :citizen_id].each do |key|
            if u[key] == row[key]
              case key
              when :citizen_id
                mcount += 2
              else
                mcount += 1
              end
            end
          end
          if mcount >= 3
            matched << { count: mcount, user: u }
          end
        end
        unless matched.empty?
          matched = matched.sort { |a,b| a[:count] <=> b[:count] }
          return matched.last[:user]
        end
        return nil
      end
      
      def get_grade_from_name(txt)
        txts = txt.to_s.split(/\s+|_/)
        txt = txts.last
        unless txt.nil?
          txt = txt.to_s.upcase
          if MS_GRADES.include?(txt)
            return txt
          end
        end
        return ""
      end
      
      def is_dummy(txt)
        txtc = txt.to_s.downcase
        if txtc =~ /^.*(dummy).*$/
          return "Y"
        elsif txtc =~ /^.*(skip customer).*$/
          return "Y"
        end
        return "N"
      end
      
      def name_and_title(name)
        n_na = nil
        n_ti = nil
        name = name.downcase
        name = cleanup_full_name(name)
        name = name.gsub(/\-\_\.\|\"\'/,"")
        name = name.gsub(/\(.+\)/,"")
        name = name.gsub(/\s+/," ").strip
        strs = /^(ms.|mrs.|mr.)?(.+)/.match(name)
        unless strs.nil?
          n_na = strs[2].split(/\s|\_/).map(&:capitalize).join(" ")
          n_ti = strs[1]
        else
          n_na = name
        end
        return n_na, n_ti
      end
      
      def cleanup_full_name(name)
        # support formats:
        # a. <x>_<name>_<x>
        if name =~ /^(\w{1,4})(\s|_)(.{5,})(\s|_)(\w{1,2})$/
          txt = name.match(/^(\w{1,4})(\s|_)(.{3,})/)
          unless txt.nil?
            if txt[1].length > 2
              tchk = txt[1].to_s.downcase.strip
              unless ['good','bad','bkk','kk','hy'].include?(tchk)
                # ignore short-name
                return name
              end
            end
            logger.info "changed name #{name} to #{txt[3]}"
            return txt[3]
          end
        end
        return name  
      end
      
      def get_possible_login_names(names)
        strs = names.split(/\s+/,2)
        loginlist = []
        loginlist << strs.first
        if strs.length >= 2
          loginlist << strs.first + strs.last[0].to_s
          loginlist << strs.first + strs.last[0].to_s + strs.last[1].to_s
          loginlist << strs.first + strs.last[0].to_s + strs.last[1].to_s + strs.last[2].to_s
        end
        return loginlist.uniq.map { |l| l.downcase }
      end
      
      def get_firstname_and_lastname(name)
        if name =~ /^(\w{5,}) (\w{5,})(\s|_)([a-zA-Z+\-]{1,2})$/
          txt = name.match(/^(\w{5,}) (\w{5,})(\s|_)([a-zA-Z+\-]{1,2})$/)
          unless txt.nil?
            name = name.gsub("#{txt[3]}#{txt[4]}","")
          end
        end
        txts = name.to_s.split(/\s+/,2)
        return { first: txts[0], last: txts[1] }
      end
      
      def get_old_users
        @odata = []
        User.order("full_name_th, id").not_deleted.all.each do |u|
          nth = get_firstname_and_lastname(u.full_name_th)
          nen = get_firstname_and_lastname(u.full_name_en)
          @odata << {
            user_id: u.id,
            login: u.login.to_s.downcase,
            employee_id: u.employee_id,
            citizen_id: u.citizen_id,
            full_name_en: u.full_name_en,
            full_name_th: u.full_name_th,
            first_name_en: nen[:first],
            last_name_en: nen[:last],
            first_name_th: nth[:first],
            last_name_th: nth[:last],
            role_id: u.role_id
          }
        end
        logger.info "existing users: #{@odata.length}"
      end
      
      def get_role(name)
        r = Role.where(name: name).first
        if r.nil?
          r = Role.new({ name: name })
          r.do_init
          r.save
        end
        return r
      end
    
      def get_team(name, id)
        if not @atl_teams[id].nil? and not @atl_teams[id][:sys_group_id].nil?
          g = Group.where(id: @atl_teams[id][:sys_group_id]).first
          unless g.nil?
            g.name = name
            g.short_name = name
            g.save
            @atl_teams[id][:name] = name
            return @atl_teams[id][:sys_group_id]
          end
        end
        g = Group.where(name: name).first
        if g.nil?
          g = Group.new({ name: name, short_name: name })
          if g.save
            Group.repair_and_update_sequence_no
          end
        end
        if not @atl_teams[id].nil?
          @atl_teams[id][:sys_group_id] = g.id
        end
        return g.id
      end
      
      def update_users
        logger.info "trying to create/update users"
        @ndata.each do |row|
          if row[:skipupdate] == true
            @counter[:skip] += 1
            logger.warn "skiped, #{row[:login]}, #{row[:full_name_en]} [#{row[:row_no]}]"
            unless row[:skip_reasons].nil?
              logger.warn "skiped reasons: #{row[:skip_reasons].join(",")}"
            end
          else
            errors = create_or_update_user(row)
            unless errors.empty?
              row[:errors] = errors
              logger.error "error: #{row[:login]}, #{row[:full_name_en]}, #{errors.join(",")} [r=#{row[:row_no]}|id=#{row[:user_id]}]"
              logger.error "error data: #{row.inspect}"
              @counter[:error] += 1
            else
              if row[:user_id].nil?
                logger.info "added: #{row[:login]}, #{row[:full_name_en]} [#{row[:row_no]}]"
                @counter[:added] += 1
              else
                logger.info "updated: #{row[:login]}, #{row[:full_name_en]} [#{row[:row_no]}]"
                @counter[:updated] += 1
              end
            end
          end
        end
      end
      
      def check_existing_emp_id(user_id, employee_id)
        # how:
        # changed old records and keep latest record
        # deleted records, add random digits
        
        usrs = User.where(employee_id: employee_id).all
        usrs.each do |usr|
          next if usr.employee_id.to_s.length <= 2
          next if user_id.to_i == usr.id
          if usr.was_deleted?
            usr.employee_id = "#{sprintf("%03d",rand(999))}#{usr.employee_id}"
            usr.save
          else
            usr.employee_id = "#{sprintf("%02d",rand(99))}#{usr.employee_id}"
            usr.save
          end
          logger.warn "found dup-employee-id, #{usr.id}, changed #{employee_id} => #{usr.employee_id}"
        end
        
        return employee_id
      end
      
      def patch_unknown_login(login)
        # fixed missing login-name
        # format: nologin<some-id>
        
        if login.blank?
          login = "nologin#{Time.now.strftime("%m%d%L")}"
        end
        return login
      end
      
      def patch_deleted_account(login, name_en, name_th)
        unless login.blank?
          usrs = User.only_deleted.where(login: login).all
          usrs.each do |usr|
            usr.login = "#{usr.login}#{usr.id}"
            usr.save
          end
        end
        unless name_en.blank?
          usrs = User.only_deleted.where(full_name_en: name_en).all
          usrs.each do |usr|
            usr.full_name_en = "#{usr.full_name_en}#{usr.id}"
            usr.save
          end
        end
        unless name_th.blank?
          usrs = User.only_deleted.where(full_name_th: name_th).all
          usrs.each do |usr|
            usr.full_name_th = "#{usr.full_name_th}#{usr.id}"
            usr.save
          end
        end
      end
      
      def patch_operator_id(operator_id)
        #usrs = User.where(atl_code: operator_id).all
      end
      
      def create_or_update_user(row)
        errors = []
        if row[:user_id].nil? or row[:user_id].to_i <= 0
          u = User.new
          u.do_active
          u.reset_default_password
        else
          u = User.where(id: row[:user_id]).first
        end
        unless u.nil?
          begin
            patch_deleted_account(row[:login],row[:full_name_en],row[:full_name_th])
          rescue => e
            logger.error "patching error before update, #{e.message}"
          end
          u.login = patch_unknown_login(row[:login])
          u.employee_id = check_existing_emp_id(row[:user_id], row[:employee_id])
          u.citizen_id = row[:citizen_id]
          u.full_name_en = row[:full_name_en]
          u.full_name_th = row[:full_name_th]
          u.atl_code = row[:operator_id]
          u.sex = "u"
          u.role_id = row[:sys_role_id]
          if u.save
            
            # team - default
            gm = u.group_member
            if gm.nil?
              gm = u.new_group_member
            end
            gm.group_id = row[:sys_group_id]
            gm.save
            
            # deliquent - default
            atype_id = UserAttribute.name_type_to_id("delinquent")
            unless atype_id.nil?
              u.update_attr({ attr_type: atype_id, attr_val: row[:delinquent] })
            end
          
            # extension
            atype_id = UserAttribute.name_type_to_id("extension")
            unless atype_id.nil?
              u.update_attr({ attr_type: atype_id, attr_val: row[:extension] })
            end

            # branch code
            atype_id = UserAttribute.name_type_to_id("branch_code")
            unless atype_id.nil?
              u.update_attr({ attr_type: atype_id, attr_val: row[:brance_code] })
            end
            
            # regions
            atype_id = UserAttribute.name_type_to_id("region_code")
            unless atype_id.nil?
              u.update_attr({ attr_type: atype_id, attr_val: row[:region_code] })
            end
                        
            # role / position
            atype_id = UserAttribute.name_type_to_id("atl-roles")
            unless atype_id.nil?
              u.update_attr({ attr_type: atype_id, attr_val: row[:role_id] })
            end

            # operator_id, team, performance_team
            if row[:attrs].nil?
              row[:attrs] = []
            end
            row[:attrs] << {
              operator_id: row[:operator_id],
              team_id: row[:team_id],
              team_name: row[:team_name],
              performance_group_id: row[:performance_group_id],
              performance_group_name: row[:performance_group_name],
              section_id: row[:section_id],
              section_name: row[:section_name],
              delinquent: row[:delinquent],
              grade: row[:grade],
              dummy: row[:dummy],
              extension: row[:extension]
            }
            unless row[:attrs].nil?
              xids = []
              # update or create new
              row[:attrs].each do |ax|
                ax[:extension] = row[:extension]
                arec = UserAtlAttr.create_or_update(u.id, ax)
                unless arec.nil?
                  xids << arec.id
                  arec.touch
                end
              end
              # remove no update
              no_upds = UserAtlAttr.where(user_id: u.id).where.not(id: xids)
              unless no_upds.empty?
                no_upds.each do |ux|
                  ux.do_delete
                  ux.save
                end
              end
            end
          else
            errors.concat(u.errors.full_messages)
          end
        else
          errors << "can not initial user"
        end
        return errors
      end
      
      def config
        return {
          host: Settings.server.aeon_atl.host,
          user: Settings.server.aeon_atl.user,
          password: Settings.server.aeon_atl.password
        }
      end
      
      def source_path
        return Settings.server.aeon_atl.filepath
      end
      
      def output_path
        dirpath = WorkingDir.make_dir(File.join(Settings.server.directory.log, "aeonatl"))
        return dirpath
      end
      
      def rename_source_file(path)
        new_path = path + "." + Time.now.strftime("%Y%m%d%H%M%S")
        File.rename(path, new_path)
        return new_path
      end
      
      def deliquent_value_map(v)
        if v.to_i <= 6
          return "D#{v}"
        end
        return nil
      end
      
      def role_name_map(v)
        return v  
      end
      
      def duty_name_map(v)
        case v.to_s.downcase
        when "operator", "agent"
          return "Agent"
        end
        return v
      end
      
      def find_login_from_computerlog(names)
        log = ComputerLog.select(:login_name).where(["check_time >= ? AND login_name IN (?)",7.days.ago, names]).order(check_time: :desc).all
        return log.map { |l| l.login_name }
      end
      
      def row_a_to_h(row)
        header = ["national_id","operator_code","employee_id","th_name","en_name","regoin_id",
                  "regoin_name","delinquent","role_id","role_name","branch_code","ext_no","performance_group_id",
                  "performance_group_name","duty","team_id","team_name","client_id","system_id","timestamp","section_id","section_name"]
        nrow = []
        row.each_with_index { |v,i|
          nrow << [header[i], v]
        }
        return nrow.to_h
      end
      
      def export_update_result
        out_fname = File.join(File.join(Settings.server.directory.log, "aeonatl"),"userlatest.csv")
        headers = [
          "username", "citizen_id", "employee_id", "eng_name", "thai_name", "operator_id",
          "delinquent","team_id", "team_name", "performance_group_id", "performance_group_name",
          "extension", "branch_code", "region_code", "region_name", "section_id", "section_name",
          "role", "duty"
        ]
        unless @ndata.empty?
          logger.info "writing updated result file."
          CSV.open(out_fname, "w", encoding: "iso-8859-11", force_quotes: true) do |csv|
            csv << headers
            @ndata.each do |ra|
              next if ra[:skipupdate] == true
              unless ra[:attrs].nil?
                ra[:attrs].each do |rb|
                  csv << [
                    ra[:login], ra[:citizen_id], ra[:employee_id], ra[:full_name_en], ra[:full_name_th], rb[:operator_id],
                    rb[:delinquent], rb[:team_id], @atl_teams[rb[:team_id]][:name], rb[:performance_group_id], @atl_perfgroup[rb[:performance_group_id]][:name],
                    rb[:extension], ra[:brance_code], ra[:region_code], ra[:region_name], ra[:section_id], @atl_sections[ra[:section_id]][:name],
                    ra[:role_name], ra[:duty]
                  ]
                end
              end
            end
          end
        end
      end
       
      # end class
    end
  end
end