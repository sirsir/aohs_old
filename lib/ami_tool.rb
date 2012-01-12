require 'yaml'

module AmiTool

  # get database information

  def get_db_info

    cf = Rails::Configuration.new
    cfi = YAML::load(IO.read(cf.database_configuration_file))

    return db_info = {
            :adapter => cfi["production"]["adapter"],
            :dbname => cfi["production"]["database"],
            :host => cfi["production"]["host"] }

  end

  # update db config

  def self.update_db_connection_string

    STDOUT.puts "=> Checking Database configuration"

    cf = Rails::Configuration.new
    cfi = YAML::load(IO.read(cf.database_configuration_file))

    cn = []
    cn << "Server=#{cfi[RAILS_ENV]["host"]}"
    cn << "Database=#{cfi[RAILS_ENV]["database"]}"
    cn << "Uid=#{cfi[RAILS_ENV]["username"]}"
    cn << "Pwd=#{cfi[RAILS_ENV]["password"]}"
    cn << "Port=3306"

    STDOUT.puts "=> DB Info #{cfi[RAILS_ENV]["host"]}@#{cfi[RAILS_ENV]["database"]}"
    
    begin
      cfd = Configuration.find(:first,:conditions => {:variable => 'mysqlDbConnectionString'})
      Configuration.update(cfd.id,{:default_value => cn.join(';')})
    rescue => e
      AmiLog.lerror(e.message)  
    end
    
  end

  # get logger active

  def get_active_logger_info

    act_id = AmiConfig.get('client.aohs_web.activeId')

    return act_id
    
  end

  # switch voice_logs table

  def self.switch_table_voice_logs
    
    checker_file = Aohs::LOGGER_ACTIVE_CHECKER_PATH 
    if File.exist?(checker_file)
      
      chk_active_id = 0
      File.open(checker_file).each do |line|
        next if line.nil?
        next if line.empty?
        chk_active_id = line.strip.gsub("active=","").to_i
      end
      
      if not Aohs::LOGGERS_ID.include?(chk_active_id)
        chk_active_id = Aohs::DEFAULT_LOGGER_ID 
      end
     
      vl_temp_table = VoiceLogTemp.table_name
      vlt_temp_table = VoiceLogToday.table_name
      vl_check_table = "voice_logs_#{chk_active_id}"
      vlt_check_table = "voice_logs_today_#{chk_active_id}"
      
      if (vl_temp_table != vl_check_table) or (vlt_temp_table != vlt_check_table)
        
         # change reference table
         VoiceLogTemp.set_table_name(vl_check_table)
         VoiceLogToday.set_table_name(vlt_check_table)
         Rails.logger.info "[voice_log-checker] - change current voice_logs_n table"
         Rails.logger.info "[voice_log-checker] - active_id=#{chk_active_id} -vltemp=#{VoiceLogTemp.table_name} -vltoday=#{VoiceLogToday.table_name}"

         # update configuration
         df_cf = Configuration.find(:first,:conditions => {:variable => "activeId"})
         df_cf = Configuration.update(df_cf.id,{:default_value => chk_active_id})
        
      end

    else
      Rails.logger.error "cannot found file :#{checker_file}"
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

  def self.check_voice_log_tables

    AmiLog.linfo("[CheckSubVoiceLogsTbl] started")

    sql = ""
    sql << " SELECT yearmonth FROM ("
    sql << " SELECT DATE_FORMAT(start_time,\"%Y%m\") as yearmonth FROM voice_logs_today_1 GROUP BY DATE_FORMAT(start_time,\"%Y%m\")"
    sql << " UNION "
    sql << " SELECT DATE_FORMAT(start_time,\"%Y%m\") as yearmonth FROM voice_logs_today_2 GROUP BY DATE_FORMAT(start_time,\"%Y%m\")"
    sql << " ) r"

    curr_tbls_vl = []

    result = VoiceLogTemp.find_by_sql(sql)
    unless result.empty?
      result.each do |r|
        curr_tbls_vl << "voice_logs_#{r.yearmonth}"
      end  
    end

    curr_tbls_vl << "voice_logs_#{(Date.today).strftime("%Y%m")}"
    curr_tbls_vl << "voice_logs_#{(Date.today + 1).strftime("%Y%m")}"  # tomorrow
    curr_tbls_vl << "voice_logs_#{(Date.today.end_of_week + 1).strftime("%Y%m")}"  # next week
    
    curr_tbls_vl = curr_tbls_vl.uniq

    tables = ActiveRecord::Base.connection.tables
    tables = tables.select { |t| t =~ /^(voice_logs_)([0-9]{4})([0-9]{2})$/i }

    AmiLog.linfo("found new : #{curr_tbls_vl.join(',')}")
    AmiLog.linfo("current : #{tables.join(',')}")

    unless curr_tbls_vl.empty?

      bln_created = false

      # create new table
   
      curr_tbls_vl.each do |t|
        if not tables.include?(t)
          AmiLog.linfo("new  table : #{t}")
          begin
            sql = "CREATE TABLE #{t} LIKE `voice_logs_template`;"
            AmiLog.linfo("-> cmd : #{sql}")
            ActiveRecord::Base.connection.execute(sql)
            bln_created = true
            tables << t
          rescue => e
            AmiLog.linfo("-> #{e.message}")
          end
        else
          AmiLog.linfo("skip table : #{t}")
        end
      end

      # alter merge

      if bln_created

          AmiLog.linfo("alter merge table")
          AmiLog.linfo("tblsVoiceLogs : #{tables.join(',')}")

          begin
            AmiLog.linfo("-> exec : alter table voice_logs engine=MRG_MyISAM")
            sql = "ALTER TABLE voice_logs ENGINE=MRG_MyISAM UNION(#{tables.join(',')})"
            AmiLog.linfo("-> cmd : #{sql}")
            ActiveRecord::Base.connection.execute(sql)
          rescue => e
            AmiLog.linfo("-> #{e.message}")
          end

          begin
            AmiLog.linfo("-> exec : alter table voice_logs_1 engine=MRG_MyISAM")
            sql = "ALTER TABLE voice_logs_1 ENGINE=MRG_MyISAM UNION(voice_logs_today_1,#{tables.join(',')})"
            AmiLog.linfo("-> cmd : #{sql}")
            ActiveRecord::Base.connection.execute(sql)
          rescue => e
            AmiLog.linfo("-> #{e.message}")
          end

          begin
            AmiLog.linfo("-> exec : alter table voice_logs_2 engine=MRG_MyISAM")
            sql = "ALTER TABLE voice_logs_2 ENGINE=MRG_MyISAM UNION(voice_logs_today_2,#{tables.join(',')})"
            AmiLog.linfo("-> cmd : #{sql}")
            ActiveRecord::Base.connection.execute(sql)
          rescue => e
            AmiLog.linfo("-> #{e.message}")
          end
        
      end

    end

    AmiLog.linfo("[CheckSubVoiceLogsTbl] finished")

  end

  def self.optimize_tables

    # daily
    tbls = ["voice_logs_today1","voice_logs_today2","result_keywords","daily_statistics","voice_logs_#{Time.new.strftime("%b").downcase}","voice_log_counters","voice_log_customers"]

    # weekly
    if Date.today.end_of_week == Date.today
      tbls = tbls.concat(["customers","taggings","weekly_statistics","monthly_statistics"])
    end

    AmiLog.linfo("[Optimize tables] started")

    tbls.each do |tbl|
      begin
        AmiLog.linfo("-> optimize table #{tbl}")
        ActiveRecord::Base.connection.execute("OPTIMIZE TABLE #{tbl};")
        AmiLog.batch_log("Batch","OptimizeTable",true,"table:#{tbl}")
      rescue => e
        AmiLog.linfo("-> optimize failed #{e.message}")
        AmiLog.batch_log("Batch","OptimizeTable",false,"table:#{tbl},#{e.message}")
      end
    end

    AmiLog.linfo("[Optimize tables] finished")
  end

end