require 'yaml'
require 'fileutils'

module AmiTool
  
  def self.public_website?(public=nil)
   
    fpublic = File.join(Rails.root,'aohs.run')
    if not public.nil?
      data = ((public == true) ? 0 : 1)
      f = File.new(fpublic,"w")
      f.puts data
      f.close
    else
      public = true
      File.open(fpublic).each do |line|
        next if line.nil? or line.empty?
        if line.to_i == 1
          public = false
          break
        end
      end
    end
    
    return public
    
  end
  
  def self.make_public_file
    fpublic = File.join(Rails.root,'aohs.run')
    if not File.exist?(fpublic)
      f = File.new(fpublic,"w")
      f.puts 0
      f.close      
    end
  end
  
  # get database information
  def get_db_info(rails_env="production")
    cfi = YAML::load(IO.read(File.join(Rails.root,'config','database.yml')))
    return db_info = {
            :adapter => cfi[rails_env]["adapter"],
            :dbname => cfi[rails_env]["database"],
            :host => cfi[rails_env]["host"] }
  end

  def self.get_db_info2(rails_env="production")
    cfi = YAML::load(IO.read(File.join(Rails.root,'config','database.yml')))
    return db_info = {
            :adapter => cfi[rails_env]["adapter"],
            :dbname => cfi[rails_env]["database"],
            :host => cfi[rails_env]["host"] }
  end
  
  def self.get_mysql_info
    data = ActiveRecord::Base.connection.select_all("SHOW VARIABLES LIKE '%version%';")
    tmp = []
    unless data.empty?
      data.each do |o|
        tmp << o["Variable_name"].to_s + "=" + o["Value"].to_s
      end
    end
    return tmp.join(", ")
  end
  
  def self.get_tables_info
    cfi = YAML::load(IO.read(File.join(Rails.root,'config','database.yml')))
    dbn = cfi["production"]["database"]
    sql = "SELECT table_name,engine,table_rows,(data_length + index_length)/1024/1024 as mb_size, data_free/1024/1024 as mb_free FROM information_schema.TABLES WHERE table_schema = '#{dbn}' and engine is not null"
    data = ActiveRecord::Base.connection.select_all(sql)
    return data
  end
  
  # update db config

  def self.update_db_connection_string

    STDOUT.puts "=> Checking Database configuration"

    cfi = YAML::load(IO.read(File.join(Rails.root,'config','database.yml')))

    cn = []
    cn << "Server=#{cfi[Rails.env]["host"]}"
    cn << "Database=#{cfi[Rails.env]["database"]}"
    cn << "Uid=#{cfi[Rails.env]["username"]}"
    cn << "Pwd=#{cfi[Rails.env]["password"]}"
    cn << "Port=3306"

    STDOUT.puts "=> DB Info #{cfi[Rails.env]["host"]}@#{cfi[Rails.env]["database"]}"
    
    begin
      cfd = Configuration.find(:first,:conditions => {:variable => 'mysqlDbConnectionString'})
      Configuration.update(cfd.id,{:default_value => cn.join(';')})
    rescue => e
      ##
    end
    
  end

  # get logger active

  def get_active_logger_info
    act_id = AmiConfig.get('client.aohs_web.activeId')
    return act_id
  end

  # switch voice_logs table

  def self.switch_table_voice_logs
    
	if Aohs::LOGGERS_ID.empty?
		VoiceLogTemp.set_table_name('voice_logs')
		VoiceLogToday.set_table_name('voice_logs_today')
		CurrentChannelStatus.set_table_name('current_channel_status')
	else
		checker_file = Aohs::LOGGER_ACTIVE_CHECKER_PATH 
		
		# checker valid
		["","_main","_sub"].each do |pfx|
			if File.exist?(checker_file + pfx)
				checker_file = checker_file + pfx
				break;
			end
		end
		
		if File.exist?(checker_file)
		  
		  begin 
			chk_active_id = Aohs::DEFAULT_LOGGER_ID
			begin
			  File.open(checker_file).each do |line|
				next if line.nil? or line.empty?
				chk_active_id = line.strip.gsub("active=","").to_i
			  end  
			rescue => e
			  STDERR.puts e.message
			end
			chk_active_id = Aohs::DEFAULT_LOGGER_ID if not Aohs::LOGGERS_ID.empty? and not Aohs::LOGGERS_ID.include?(chk_active_id)     
			
			[VoiceLogTemp,VoiceLogToday,CurrentChannelStatus].each do |md|
			  oldtbl = md.table_name
			  newtbl = md.table_name_prefix + chk_active_id.to_s
			  if oldtbl != newtbl
				STDOUT.puts "[VoiceLogsSwitcher] - update class=#{md.name}, act_id=#{chk_active_id}, table_name=#{oldtbl}=>#{newtbl}"
				md.set_table_name(newtbl)
			  else
				##STDOUT.puts "[VoiceLogsSwitcher] - no change #{md.name}"
			  end
			end

			df_cf = Configuration.where({:variable => "activeId"}).first
			df_cf = Configuration.update(df_cf.id,{:default_value => chk_active_id})
					
		  rescue => e
			STDERR.puts e.message
		  end

		end
	end
  end

  # switch database connection
  
  def self.aohs_switch_db

    AmiLog.linfo("[SwitchAohsDB] started")

    rails_env = "production"
    AmiLog.linfo("rails env => #{rails_env}")
    
    rails_cf = Rails::Configuration.new
    db_conf_file = rails_cf.database_configuration_file

    current_db_ip = nil
    dbf = false
    actf = false

    if File.exist?(db_conf_file)
      
	  cf = YAML::load(IO.read(db_conf_file))

      AmiLog.linfo("switching database connection to ..")
      AmiLog.lerror("-> host: #{cf[rails_env]["host"]}")
      AmiLog.lerror("-> db_name: #{cf[rails_env]["database"]}")
      
      ActiveRecord::Base.establish_connection(
        :adapter  => cf[rails_env]["adapter"],
        :database => cf[rails_env]["database"],
        :host     => cf[rails_env]["host"],
        :username => cf[rails_env]["username"],
        :password => cf[rails_env]["password"]
      )
           
    else
      AmiLog.lerror("database.yml not found.")
    end

  end

  # check sub voice_logs tables
  def self.verify_voice_log_tables
        
    STDOUT.puts "[AmiTool - verify_voice_log_tables] batch started"

    voice_logs_monthly = []
    
    STDOUT.puts "[AmiTool - verify_voice_log_tables] verifying all voice_logs tables"
    
    # check monthly voice_log from data
    
    tbl_voice_logs_list = ["voice_logs","voice_logs"]
    tbl_voice_logs_list.each do |tb|
      sql = "SELECT DATE_FORMAT(start_time,'%Y%m') as yearmonth FROM voice_logs GROUP BY DATE_FORMAT(start_time,'%Y%m')"
      result = ActiveRecord::Base.connection.select(sql)
      unless result.empty?
        voice_logs_monthly = voice_logs_monthly.concat(result.map { |r| Aohs::VLTBL_PREFIX + r['yearmonth'] })
      end
    end
    
    # check monthly voice_log current and next
    
    voice_logs_monthly << Aohs::VLTBL_PREFIX + "#{(Date.today).strftime("%Y%m")}"
    voice_logs_monthly << Aohs::VLTBL_PREFIX + "#{(Date.today + 2).strftime("%Y%m")}"
    
    # check exist voice_logs
    
    STDOUT.puts "[AmiTool - verify_voice_log_tables] updating voice_logs tables to database"
    
    unless voice_logs_monthly.empty?
      voice_logs_monthly = voice_logs_monthly.uniq.sort
      
      db_tables = ActiveRecord::Base.connection.tables
      db_tables = db_tables.select { |t| t =~ /^(voice_logs_)([0-9]{4})([0-9]{2})$/i }
      
      voice_logs_monthly.each do |m|
        if db_tables.include?(m)
          STDOUT.puts "[AmiTool - verify_voice_log_tables]  exists #{m}"
        else
          STDOUT.puts "[AmiTool - verify_voice_log_tables]  create #{m}"
          sql = "CREATE TABLE #{m} LIKE `voice_logs_template`;"
          ActiveRecord::Base.connection.execute(sql)
        end
      end
      
      voice_logs_monthly = voice_logs_monthly.concat(db_tables)
      voice_logs_monthly = voice_logs_monthly.uniq
      
      STDOUT.puts "[AmiTool - verify_voice_log_tables] list(#{voice_logs_monthly.length}) => #{voice_logs_monthly.join(',')}"
      
      STDOUT.puts "[AmiTool - verify_voice_log_tables] merging voice_logs tables"
           
      begin 
        STDOUT.puts "[AmiTool - verify_voice_log_tables] merging voice_logs table (current voice_logs)"
        sql = "ALTER TABLE voice_logs ENGINE=MRG_MyISAM UNION(#{voice_logs_monthly.join(',')})"
        ActiveRecord::Base.connection.execute(sql)           
      rescue => e
        STDOUT.puts "[AmiTool - verify_voice_log_tables] #{e.message}"
      end      
      
	  if Aohs::LOGGERS_ID.empty?
		begin
		  STDOUT.puts "[AmiTool - verify_voice_log_tables] merging voice_logs table and temporary voice_logs_today"
		  sql = "ALTER TABLE voice_logs ENGINE=MRG_MyISAM UNION(voice_logs_today,#{voice_logs_monthly.join(',')})" 
		  ActiveRecord::Base.connection.execute(sql)     
		rescue => e
		  STDOUT.puts "[AmiTool - verify_voice_log_tables] #{e.message}"
		end   	  
	  else
		  Aohs::LOGGERS_ID.each do |l|
			begin
			  STDOUT.puts "[AmiTool - verify_voice_log_tables] merging voice_logs_#{l} table and temporary voice_logs_today_#{l}"
			  sql = "ALTER TABLE voice_logs_#{l} ENGINE=MRG_MyISAM UNION(voice_logs_today_#{l},#{voice_logs_monthly.join(',')})"
			  ActiveRecord::Base.connection.execute(sql)    
			rescue => e
			  STDOUT.puts "[AmiTool - verify_voice_log_tables] #{e.message}"
			end        
		  end	  
	  end    
    end

  end

  def self.clean_temp_map_table
    
    STDOUT.puts "[cleanup_tmp_table] - table [#{DidAgentMap.name},#{ExtensionToAgentMap.name}] "

    begin
      [DidAgentMap,ExtensionToAgentMap].each do |md|
        
        STDOUT.puts "[cleanup_tmp_table] - deleting data table #{md.table_name}"
        
        rs = md.delete_all()
        rs = md.connection.execute("ALTER TABLE #{md.table_name} AUTO_INCREMENT = 1")
        AmiLog.batch_log("Batch","ExtensionMap",true,"Cleanup Temporary table #{md.table_name}")
        
      end
    rescue => e
      AmiLog.batch_log("Batch","ExtensionMap",false,e.message)
    end

  end

  def self.update_none_role_to_agent
    
    STDOUT.puts "[ErrorNoRole] - checking role of user"
    
    default_role = Role.where(:name => "Agent").first
    
    users = User.alive.all
    users.each do |u|
      if u.role.nil?
        STDOUT.puts "[ErrorNoRole] - update usr=#{u.id},old_role=#{u.role_id},new_role=#{default_role.id}"
        u.update_attributes(:role_id => default_role.id)  
      end
    end
     
  end
  
  def self.install_admin_tool
      
      admin_path = Aohs::INSTALL_ADMIN_PATH
      root_app = Rails.root
      
      STDOUT.puts "[AmiTool - admin installation] - admin installation"
      STDOUT.puts "[AmiTool - admin installation] - destination path is #{admin_path}"
      STDOUT.puts "[AmiTool - admin installation] - installing"
      
      begin
        
        if not File.exist?(admin_path)
          FileUtils.mkdir(admin_path,:mode => 0775)    
        end
        
        files = Dir.glob(File.join(root_app,"*"))
        files.each do |f|
          next if File.directory?(f)
          FileUtils.cp(f,f.gsub(root_app,admin_path))
        end
        
        ['app/models','config','db','lib','vendor'].each do |folder|
            path_reg = File.join(root_app,folder,"**", "*")
            #STDOUT.puts "[AmiTool - admin installation] - #{path_reg}"
            files = Dir.glob(path_reg)
            begin
              files.each do |f|
                begin
                  src = f
                  des = f.gsub(root_app,admin_path)
                  FileUtils.makedirs(File.dirname(des)) if not File.exist?(File.dirname(des))
                  #STDOUT.puts "#{f} => #{f.gsub(root_app,admin_path)}"
                  FileUtils.cp(src,des)  
                rescue => e
                  STDERR.puts "[AmiTool - admin installation] - setup failed #{e.message}"
                end
              end
            rescue => e
              STDERR.puts "[AmiTool - admin installation] - setup failed #{e.message}"
            end
        end
        
        FileUtils.chmod_R(0775,admin_path)
      
      rescue => e
        STDERR.puts "[AmiTool - admin installation] - setup failed #{e.message}"
      end
    
      STDOUT.puts "[AmiTool - admin installation] - setup successfully"
      
  end
  
  def self.cleaning_status_log_table
    
    STDOUT.puts "[CleanupStatusTable] - started"
    
    rem_day = Date.today - Aohs::DAY_KEEP_STATUS_LOG
    
    STDOUT.puts "[CleanupStatusTable] - remove data after checktime #{rem_day}"
    
    [CurrentComputerStatus,CurrentWatcherStatus].each do |tbl|
      
       rem_recs = tbl.where(["check_time <= ? ",rem_day]).all
       
       STDOUT.puts "[CleanupStatusTable] - #{tbl.name}, removed #{rem_recs.length} records"
       tbl.delete(rem_recs)
       
    end
    
    STDOUT.puts "[CleanupStatusTable] - finished"
    
  end
	
	#
	## Maakit Table syncer
	#
	
	def self.database_syncer
    
		STDOUT.puts "[SyncMasterData] - started"
    
		exec_path = "mk-table-sync"
		
		cf = YAML::load(IO.read(File.join(Rails.root,'config','maakit.yml')))
		
		masterdb_config = cf["master"]
		slavedb_config = cf["slave"]
		
		run_option = :same_server
		if Aohs::MAAKIT_SYNCER_OPTION == :auto
			if masterdb_config["host"] == slavedb_config["host"]
				run_option = :same_server
			else
				run_option = :cross_server
			end
		else
			run_option = Aohs::MAAKIT_SYNCER_OPTION
		end
		
		tables_list_fname = File.join(Rails.root,"config",Aohs::MAAKIT_TABLE_SRCLIST)
    
		if File.exist?(tables_list_fname)
			File.open(tables_list_fname).each do |line|
        
				next if line =~ /^#/
				next if line.blank?
        
				table_name = line.to_s.gsub(/ /,"").gsub("\r\n","").gsub("\n","")
				STDOUT.puts "[SyncMasterData] - table name : #{table_name}"
				
				cmd = "#{exec_path} --execute "
				case run_option
				when :cross_server
					cmd << " u=#{masterdb_config['username']},p=#{masterdb_config['password']},D=#{masterdb_config['database']},t=#{table_name} u=#{slavedb_config['username']},h=#{slavedb_config['host']},p=#{slavedb_config['password']},D=#{slavedb_config['database']}"
				else
					cmd << " u=#{masterdb_config['username']},p=#{masterdb_config['password']},D=#{masterdb_config['database']},t=#{table_name} D=#{slavedb_config['database']}"
				end
				
				STDOUT.puts cmd
				system cmd
			end
		end
    
		STDOUT.puts "[SyncMasterData] - finished"
  end
  
  def self.auto_remove_inactive_users
    
    delete_before = 1.year.ago.strftime("%Y-%m-%d ")
    inactive_users = User.where("state != 'active' AND flag = false AND DATE(updated_at) <= '#{delete_before}'").all
    
    unless inactive_users.empty?
      inactive_users.each do |usr|
        usr.login = usr.get_deleted_login_name
        if usr.type == "Manager"
          manager = Manager.where(usr.id).first
          manager.deleted_releated_data unless manager.nil?
        end
        usr.do_delete
        usr.state = "deleted"
        usr.save
      end
    end
    
    STDOUT.puts "[MarkDeleteInactiveUsr] - To deleted #{inactive_users.count} records "
    
  end
  
end
