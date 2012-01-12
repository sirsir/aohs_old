namespace :application do
  
   desc 'Setup App'
   task :setup => :environment do

   end

   desc 'help'
   task :help do
        
        STDOUT.puts ""
        STDOUT.puts " - Setup application                 application:rebuild"
        STDOUT.puts " - Repair Triggers                   application:triggers"  
        STDOUT.puts " - Reset Statistics data             application:statistics:repair"
        STDOUT.puts " - Reset VoiceLog counter            application:vl_counter"
        STDOUT.puts " - Update Configuration              application:configuration:update"
        STDOUT.puts " - Update permission                 application:permisssion:update"  
        STDOUT.puts ""
        
   end

   desc 'build application'
   task :create => :setup do

      Rake::Task["db:migrate"].invoke
      Rake::Task["application:voice_logs"].invoke
      Rake::Task["application:triggers"].invoke
      
      Rake::Task["application:configuration:create"].invoke
      Rake::Task["application:permission:create"].invoke
      Rake::Task["application:statistics:create_statistics_type"].invoke

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
      Rake::Task["application:voice_logs"].invoke
      Rake::Task["application:triggers"].invoke
      
      Rake::Task["application:configuration"].invoke
      Rake::Task["application:permission"].invoke
      Rake::Task["application:statistics"].invoke

   end

   desc 'create voice_logs'
   task :voice_logs => :setup do
     
     STDOUT.puts "Create Table voice_logs"
     
     begin
       desc_info = ActiveRecord::Base.connection.execute("SHOW CREATE TABLE voice_logs").first
       create_sql = desc_info["Create Table"].gsub("CREATE TABLE `voice_logs`","")
       
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
       
       ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS voice_logs")
       ActiveRecord::Base.connection.execute("CREATE TABLE `voice_logs` #{create_sql} ENGINE=MRG_MyISAM DEFAULT CHARSET=utf8 INSERT_METHOD=LAST UNION=(#{monthly_names});")
       
       ([1,2]).each do |tbl_no|
          begin
          ActiveRecord::Base.connection.execute("CREATE TABLE voice_logs_today_#{tbl_no} LIKE voice_logs_template;")
          rescue => e
            STDOUT.puts e.message
          end
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS voice_logs_#{tbl_no}")
          ActiveRecord::Base.connection.execute("CREATE TABLE `voice_logs_#{tbl_no}` #{create_sql} ENGINE=MRG_MyISAM DEFAULT CHARSET=utf8 INSERT_METHOD=LAST UNION=(#{monthly_names},`voice_logs_today_#{tbl_no}`);"); 
       end
     rescue => e
        STDOUT.puts e.message
     end
     
     STDOUT.puts "Create voice_logs was successfully."
     
   end
   
   desc 'create trigger'
   task :triggers => :setup do

     STDOUT.puts "Create Trigger"
     
     triggers_files = Dir.glob(File.join(RAILS_ROOT,'db','migrate','trigger','*.sql'))

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

       sql_drop = "DROP TRIGGER IF EXISTS #{trigger_name}"
       STDOUT.puts " -- DROP Trigger ..."
       rs = ActiveRecord::Base.connection.execute(sql_drop)
       STDOUT.puts sql_drop
       STDOUT.puts " #{rs}"

       STDOUT.puts " -- CREATE Trigger ..."
       rs = ActiveRecord::Base.connection.execute(sql)
       STDOUT.puts sql
       STDOUT.puts " #{rs}"
       
     end
     
   end
  
   desc 'create_voice_logs_counter'
   task :vl_counter => :setup do 
    
      STDOUT.puts "Chceking voice_logs_counter"
      
      STDOUT.puts " -- Delete all voice_logs_counter"
      VoiceLogCounter.delete_all()
      
      st_time = VoiceLogTemp.minimum(:start_time) || Time.now
      ed_time = VoiceLogTemp.maximum(:start_time) || Time.now
      st_time = st_time.to_date
      ed_time = ed_time.to_date
      
      STDOUT.puts " -- Update voice_logs_counter"
      
      (st_time..ed_time).to_a.each do |t|
        
        chk_date = t.strftime("%Y-%m-%d")
        STDOUT.puts " -- DATE: #{chk_date}"
        
        vls = VoiceLogTemp.find(:all,:conditions => "start_time between '#{chk_date} 00:00:00' and '#{chk_date} 23:59:59' ")
        
        unless vls.empty?
          vls.each do |vl|
            vl_id = vl.id  
            
            mustword1 = ResultKeyword.count(:id,:conditions => "result_keywords.voice_log_id = #{vl_id} and result_keywords.edit_status is null and keywords.deleted = false and keywords.keyword_type = 'm'",:joins => :keyword) || 0 
            ngword1 = ResultKeyword.count(:id,:conditions => "result_keywords.voice_log_id = #{vl_id} and result_keywords.edit_status is null and keywords.deleted = false and keywords.keyword_type = 'n'",:joins => :keyword) || 0
            mustword2 = EditKeyword.count(:id,:conditions => "edit_keywords.voice_log_id = #{vl_id} and edit_keywords.edit_status in ('n','e') and keywords.deleted = false and keywords.keyword_type = 'm'",:joins => :keyword) || 0 
            ngword2 = EditKeyword.count(:id,:conditions => "edit_keywords.voice_log_id = #{vl_id} and edit_keywords.edit_status in ('n','e') and keywords.deleted = false and keywords.keyword_type = 'n'",:joins => :keyword) || 0 
            
            bookmark = CallBookmark.count(:id,:conditions => "call_bookmarks.voice_log_id = #{vl_id}") || 0
             
            mustword = mustword1.to_i + mustword2.to_i
            ngword = ngword1.to_i + ngword2.to_i
            
            VoiceLogCounter.create({:voice_log_id => vl_id,:bookmark_count => bookmark,:ngword_count => ngword, :mustword_count => mustword})
            
            STDOUT.puts "   : #{vl_id}\t#{bookmark}\t#{mustword}\t#{ngword} "
            
          end
        else
          STDOUT.puts " -- No update"
        end
        
      end
      
      
      STDOUT.puts "End ..."
      
   end
 
   desc 'repair_statistics'
   task :repair_statistics => :setup do 
      Rake::Task["application:statistics:repair"].invoke   
   end
   
   desc 'dnis_agent_update'
   task :dnis_agent_update => :setup do 
       
      dau = DnisAgentUpdater.new
      dau.update
      
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
   
   desc 're_pair user'
   task :reset_password => :setup do 
       
       new_password = "password"
       
       User.find(:all,:conditions => "login not like 'aohsadmin' ").each do |u|
        STDOUT.puts "#{u.login} => #{new_password}-#{u.update_attributes({:password => new_password ,:password_confirmation => new_password})}"
       end
     
 end 
 
end
