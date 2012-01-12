namespace :application do
  
   desc 'Setup App'
   task :setup => :environment do

   end
 
   desc 'help'
   task :help do
        
        STDOUT.puts ""
        STDOUT.puts " - Setup application                 application:rebuild"
        STDOUT.puts " - Repair Functions                  application:func"
        STDOUT.puts " - Repair Triggers                   application:triggers"  
        STDOUT.puts " - Statistics data (Today)           application:statistics:repair_today"
        STDOUT.puts " - Statistics data                   application:statistics:repair_all"
        STDOUT.puts " - Statistics data (Clean)           application:statistics:reset_daily"		
        STDOUT.puts " - Statistics data (Clean)           application:statistics:reset"
        STDOUT.puts " - Reset VoiceLog counter            application:voice_logs:voice_log_counter"
        STDOUT.puts " - Recheck voice_logs table          application:voice_logs_table"
		    STDOUT.puts " - Reset User's password             application:reset_password"
        STDOUT.puts " - Update Configuration              application:configuration:update"
        STDOUT.puts " - Update permission                 application:permisssion:update"  
        STDOUT.puts ""
        
   end

   desc 'build application'
   task :create => :setup do

      Rake::Task["db:migrate"].invoke
      Rake::Task["application:voice_logs_table"].invoke
      Rake::Task["application:channel_status"].invoke
      Rake::Task["application:func"].invoke
      Rake::Task["application:triggers"].invoke
      
      Rake::Task["application:configuration:create"].invoke
      Rake::Task["application:permission:create"].invoke
      Rake::Task["application:statistics:types"].invoke

   end

   desc 'remove application'
   task :remove => :setup do

      Rake::Task["application:configuration:remove"].invoke
      Rake::Task["application:permission:remove"].invoke
      Rake::Task["application:statistics:remove_statistics_type"].invoke

   end

   desc 'rebuild application'
   task :rebuild => :setup do

      Rake::Task["db:migrate"].invoke
      Rake::Task["application:voice_logs_table"].invoke
      Rake::Task["application:channel_status"].invoke
      Rake::Task["application:func"].invoke
	    Rake::Task["application:triggers"].invoke
      
      Rake::Task["application:configuration"].invoke
      Rake::Task["application:permission"].invoke
      Rake::Task["application:statistics"].invoke

   end

   desc 'create voice_logs'
   task :voice_logs_table => :setup do
     
     if not Aohs::LOGGERS_ID.nil? ## and not Aohs::LOGGERS_ID.empty?
     
       STDOUT.puts "Create Table voice_logs"
       
       begin
         desc_info = ActiveRecord::Base.connection.execute("SHOW CREATE TABLE voice_logs").first
         create_sql = desc_info["Create Table"].gsub("CREATE TABLE `voice_logs`","").gsub("PRIMARY KEY (`id`)","UNIQUE KEY `index_id` (`id`)")
         
         STDOUT.puts " Rename Table voice_logs => voice_logs_template"
         ActiveRecord::Base.connection.execute("ALTER TABLE `voice_logs` ENGINE = MyISAM;")
         ActiveRecord::Base.connection.execute("ALTER TABLE `voice_logs` RENAME TO `voice_logs_template`;")
       rescue => e
          desc_info = ActiveRecord::Base.connection.execute("SHOW CREATE TABLE voice_logs_template").first
          create_sql = desc_info["Create Table"].gsub("CREATE TABLE `voice_logs_template`","")
          STDOUT.puts e.message
       end
       
       begin
         STDOUT.puts " Create Table monthly voice_logs"
         monthly_names = []
         monthly_names << Date.today.beginning_of_month.strftime("%Y%m")
         monthly_names.each do |mn|
          ActiveRecord::Base.connection.execute("CREATE TABLE voice_logs_#{mn} LIKE voice_logs_template;");
         end
       rescue => e
          STDOUT.puts e.message
       end
       
       begin
         STDOUT.puts " Create Table merge voice_logs"
         monthly_names = (monthly_names.map { |m| "voice_logs_#{m}" }).join(",")
                  
		 if Aohs::LOGGERS_ID.empty?
				begin
				  ActiveRecord::Base.connection.execute("CREATE TABLE voice_logs_today LIKE voice_logs_template;")
				rescue => e
				  STDOUT.puts e.message
				end
				ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS voice_logs")
				ActiveRecord::Base.connection.execute("CREATE TABLE `voice_logs` #{create_sql} ENGINE=MRG_MyISAM DEFAULT CHARSET=utf8 INSERT_METHOD=LAST UNION=(#{monthly_names},`voice_logs_today`);"); 		 
		 else
			  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS voice_logs")
			  ActiveRecord::Base.connection.execute("CREATE TABLE `voice_logs` #{create_sql} ENGINE=MRG_MyISAM DEFAULT CHARSET=utf8 INSERT_METHOD=LAST UNION=(#{monthly_names});")
		 
			 (Aohs::LOGGERS_ID).each do |tbl_no|
				begin
				  ActiveRecord::Base.connection.execute("CREATE TABLE voice_logs_today_#{tbl_no} LIKE voice_logs_template;")
				rescue => e
				  STDOUT.puts e.message
				end
				ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS voice_logs_#{tbl_no}")
				ActiveRecord::Base.connection.execute("CREATE TABLE `voice_logs_#{tbl_no}` #{create_sql} ENGINE=MRG_MyISAM DEFAULT CHARSET=utf8 INSERT_METHOD=LAST UNION=(#{monthly_names},`voice_logs_today_#{tbl_no}`);"); 
			 end
		 end
       rescue => e
          STDOUT.puts e.message
       end
     
     else
        STDOUT.puts "Skip create Table voice_logs"
     end
   
     STDOUT.puts "Create voice_logs was successfully."
     
   end

   desc 'create voice_logs'
   task :channel_status => :setup do
    
    unless  Aohs::LOGGERS_ID.empty?
      STDOUT.puts " Create Table current_channel_status"
      (Aohs::LOGGERS_ID).each do |tbl_no|  	  
            ActiveRecord::Base.connection.execute("CREATE TABLE current_channel_status_#{tbl_no} LIKE current_channel_status;");                    
      end
      STDOUT.puts " DROP Table current_channel_status"
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS current_channel_status")   
    else
	  # do not change current channel status
    end

   end
   
   desc 'create trigger'
   task :triggers => :setup do

     STDOUT.puts "Create Trigger"
     
     triggers_files = Dir.glob(File.join(Rails.root,'db','migrate','trigger','*.sql'))
  
     case Aohs::CURRENT_LOGGER_TYPE
      when :eone
        triggers_files.concat(Dir.glob(File.join(Rails.root,'db','migrate','trigger_eone','*.sql'))) 
      when :extension
	    if Aohs::LOGGERS_ID.empty?
			triggers_files.concat(Dir.glob(File.join(Rails.root,'db','migrate','trigger_extensions_single','*.sql'))) 
		else
			triggers_files.concat(Dir.glob(File.join(Rails.root,'db','migrate','trigger_extensions','*.sql'))) 
		end
     end
     
     triggers_files.each do |tf|
       STDOUT.puts " -- Read :#{tf}"

       trigger_name = nil
       sql = ""
       File.open(tf,"r").each do |l|
          next if l.blank? 
          if trigger_name.nil?
            trigger_name = l.gsub("--TriggerName=","").strip
          else
            sql << l
          end
       end
       STDOUT.puts " -- Trigger name :#{trigger_name}"
       
       begin
         
         sql_drop = "DROP TRIGGER IF EXISTS #{trigger_name}"
         STDOUT.puts " -- DROP Trigger ..."
         rs = ActiveRecord::Base.connection.execute(sql_drop)
         #STDOUT.puts sql_drop
         STDOUT.puts " #{rs}"
  
         STDOUT.puts " -- CREATE Trigger ..."
         rs = ActiveRecord::Base.connection.execute(sql)
         #STDOUT.puts sql
         STDOUT.puts " #{rs}"
       
       rescue => e
          STDOUT.puts " -- error : #{e.message}"
       end
     
     end
     
   end
  
   desc 'procedure_and_function'
   task :func => :setup do
     
     STDOUT.puts "Create Function"
     ['Function','Procedure'].each do |t|
       
       proc_files = Dir.glob(File.join(RAILS_ROOT,'db','migrate',t.downcase,'*.sql'))
        
       proc_files.each do |f|
         STDOUT.puts " -- Read :#{f}"
  
         proc_name = nil
         sql = ""
         File.open(f,"r").each do |l|
            next if l.blank?
            if proc_name.nil?
              proc_name = l.gsub("--#{t}Name=","").strip
            else
              sql << l
            end
         end
         STDOUT.puts " -- #{t} name :#{proc_name}"
  
         sql_drop = "DROP #{t} IF EXISTS #{proc_name}"
         STDOUT.puts " -- DROP #{t} ..."
         rs = ActiveRecord::Base.connection.execute(sql_drop)
         #STDOUT.puts sql_drop
         STDOUT.puts " #{rs}"
  
         STDOUT.puts " -- CREATE #{t} ..."
         rs = ActiveRecord::Base.connection.execute(sql)
         #STDOUT.puts sql
         STDOUT.puts " #{rs}"       
       end
     
     end
     
   end

   desc 'test_schedulers'
   task :test_schedulers => :setup do
      AmiScheduler.test_sched
   end
   
   desc 'repair_statistics'
   task :repair_statistics => :setup do 
      Rake::Task["application:statistics:repair"].invoke   
   end
    
   desc 'tblsync'
   task :db_syncer => :setup do 
      AmiTool.database_syncer
   end
  
   desc 're_pair user'
   task :repair_users => :setup do 
       
       User.find(:all).each do |u|
       
         login = u.login.downcase
         display_name = (u.display_name.strip.split(" ").map { |t| t.capitalize }).join (" ")
         id_card = u.id_card.to_s.gsub("","")
                 
         STDOUT.puts "\n"
         STDOUT.puts "OLD: #{u.login}, #{u.display_name}, #{u.id_card}"
         u.login = login
         u.display_name = display_name
         u.id_card = id_card         
         STDOUT.puts "NEW: #{login}, #{display_name}, #{id_card} => #{u.save}"
         
       end
   end
   
   desc 'reset user password to default'
   task :reset_password => :setup do 
       
       new_password = Aohs::DEFAULT_PASSWORD_NEW
       User.where("login not like 'aohsadmin'").each do |u|
         STDOUT.puts "#{u.login} => #{new_password}-#{u.update_attributes({:password => new_password ,:password_confirmation => new_password})}"
       end
     
   end 

   desc 'admin_setup'
   task :admin_setup => :setup do
      AmiTool.install_admin_tool 
   end
  
end
