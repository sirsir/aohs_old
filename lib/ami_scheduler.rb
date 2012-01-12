require File.join(RAILS_ROOT,'vendor/plugins','rufus-scheduler','lib','rufus','scheduler')

module AmiScheduler

  extend self
  extend AmiStatisticsReport
    
  def run

    STDOUT.puts "=> Scheduler starting .."
    STDOUT.puts "=> :: AmiTool.switch_table_voice_logs [ Started ]"
     
    scheduler0 = Rufus::Scheduler.start_new
    scheduler0.cron "*/1 * * * *" do
       begin
         AmiTool.switch_table_voice_logs
       rescue => e
         STDERR.puts e.message
       end 
    end
     
    STDOUT.puts "=> :: AmiTool.check_voice_log_tables [ Started ]"
    STDOUT.puts "=> :: StatisticsReport.statistics_main_agents [ Started ]"
    STDOUT.puts "=> :: StatisticsReport.statistics_main_jobs [ Started ]"
    STDOUT.puts "=> :: StatisticsReport.statistics_main_keywords [ Started ]"
    STDOUT.puts "=> :: Reset Extension Mapping data [ Started ]"
    STDOUT.puts "=> :: Log Backup [ Stopped ]"
    STDOUT.puts "=> :: Optimize Data [ Stopped ]"
    
     scheduler1 = Rufus::Scheduler.start_new
     scheduler1.cron "0 2 * * *" do  
        AmiTool.check_voice_log_tables
        statistics_main_agents
        statistics_main_jobs
        statistics_main_keywords
        do_clear_map_table
        AmiLog.auto_backup_log
        #AmiTool.optimize_tables         # for optimize
     end

     STDOUT.puts "=> :: Auto synchronize DnisAgents [ Stopped ]"
     
     scheduler2 = Rufus::Scheduler.start_new
     scheduler2.in '2s'do
       #auto_sync_genesys_urs
     end

  end
  
  ## ========= ##

  def do_clear_map_table
  
    AmiLog.linfo("[clear_map_table] - table [#{DidAgentMap.class_name},#{ExtensionToAgentMap.class_name}] ")
    begin
      
      [DidAgentMap,ExtensionToAgentMap].each do |md|
        AmiLog.linfo("[clear_map_table] - deleting data table #{md.table_name}")
        rs = md.delete_all()
        rs = md.connection.execute("ALTER TABLE #{md.table_name} AUTO_INCREMENT = 1")
      end
      AmiLog.batch_log("Batch","ExtensionMap",true)
    rescue => e
      AmiLog.batch_log("Batch","ExtensionMap",false,e.message)
      AmiLog.lerror("#{e.message}")
    end

  end
  
  def auto_sync_genesys_urs
    
    begin
      dau = DnisAgentUpdater.new
      dau.update      
    rescue => e
      STDERR.puts e.message
    end
   
  end
  
end