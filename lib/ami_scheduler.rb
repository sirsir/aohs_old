require 'rufus/scheduler'
require 'fileutils'

module AmiScheduler

  extend self
  extend AmiStatisticsReport
    
  JS_RUNNING = "RUNNING"
  JS_PENDING = "PENDING"
  JS_ERROR   = "ERROR"
  JS_STOP    = "STOPPED"
  JS_DEFAULT = JS_STOP
  
  def test_sched
    daily_list  
    weekly_list 
  end
   
  def run
    
    if Aohs::SCHEDULE_ALL
      
      STDOUT.puts "=> Initialize schedule jobs"
      jmklist
      
      # every mintue
      #scheduler0 = Rufus::Scheduler.start_new
      #scheduler0.cron "*/1 * * * *" do
        #if jstart?("Tool.VoiceLogSwitcher")
      #    begin
      #      jstatus("Tool.VoiceLogSwitcher",JS_RUNNING)
            #AmiTool.switch_table_voice_logs
      #    rescue => e
      #      jstatus("Tool.VoiceLogSwitcher",JS_ERROR)
      #      STDERR.puts e.message
      #    end  
        #end
      #end
      
      AmiTool.switch_table_voice_logs
      
      # hourly check 
      scheduler3 = Rufus::Scheduler.start_new
      scheduler3.cron "0 #{Aohs::WORKING_HR_PERIOD} * * *", :allow_overlapping => false do  
    	  if Aohs::SCHEDULE_PERHOUR_RUN
    		  hourly_list
    	  end
      end
  	
      # daily check 
      scheduler1 = Rufus::Scheduler.start_new
      scheduler1.cron "0 4 * * *", :allow_overlapping => false do  
    	  if Aohs::SCHEDULE_DAILY_RUN 
    		  daily_list
    	  end
      end
      
      # weekly check [sunday]
      # (1 = Sunday) or by using the strings SUN, MON, TUE, WED, THU, FRI and SAT
      scheduler2 = Rufus::Scheduler.start_new
      scheduler2.cron "0 12 * * SUN", :allow_overlapping => false do  
    	  if Aohs::SCHEDULE_WEEKLY_RUN
    		  weekly_list
    	  end
    	end
     
    end
  
  end
  
  def hourly_list
  
    if jstart?("Statistics.StatisticsAgentsToday")
      begin
        jstatus("Statistics.StatisticsAgentsToday",JS_RUNNING)
        statistics_main_agents
        jstatus("Statistics.StatisticsAgentsToday",JS_PENDING)
      rescue => e
        jstatus("Statistics.StatisticsAgentsToday",JS_ERROR)
        STDERR.puts e.message
      end      
    end
    
    if jstart?("Statistics.StatisticsKeywordsToday")
      begin
        jstatus("Statistics.StatisticsKeywordsToday",JS_RUNNING)
        statistics_main_keywords
        jstatus("Statistics.StatisticsKeywordsToday",JS_PENDING)
      rescue => e
        jstatus("Statistics.StatisticsKeywordsToday",JS_ERROR)
        STDERR.puts e.message
      end 
    end  

    if jstart?("Tool.DatabaseSyncer")
      begin
        jstatus("Tool.DatabaseSyncer",JS_RUNNING)
        AmiTool.database_syncer
        jstatus("Tool.DatabaseSyncer",JS_PENDING)
      rescue => e
        jstatus("Tool.DatabaseSyncer",JS_ERROR)
        STDERR.puts e.message
      end 
    end  
    
  end
  
  def daily_list
    STDOUT.puts "[Scheduler] daily started at #{Time.new}"

    if jstart?("Tool.VerifyVoiceLogTable")
      begin
        jstatus("Tool.VerifyVoiceLogTable",JS_RUNNING)
        AmiTool.verify_voice_log_tables
        jstatus("Tool.VerifyVoiceLogTable",JS_PENDING)
      rescue => e
        jstatus("Tool.VerifyVoiceLogTable",JS_ERROR)
        STDERR.puts e.message
      end
    end
    
    if jstart?("VoiceLog.RepairVoiceLogCounter")
      begin
        jstatus("VoiceLog.RepairVoiceLogCounter",JS_RUNNING)
        AmiVoiceLog.repair_voice_log_counters_daily
        jstatus("VoiceLog.RepairVoiceLogCounter",JS_PENDING)
      rescue => e
        jstatus("VoiceLog.RepairVoiceLogCounter",JS_ERROR)
        STDERR.puts e.message
      end
    end
    
    if jstart?("Statistics.DailyStatistics")
      begin
        jstatus("Statistics.DailyStatistics",JS_RUNNING)
        statistics_daily_repair
        jstatus("Statistics.DailyStatistics",JS_PENDING)
      rescue => e
        jstatus("Statistics.DailyStatistics",JS_ERROR)
        STDERR.puts e.message
      end
    end
  
    if jstart?("Statistics.StatisticsAgents")
      begin
        jstatus("Statistics.StatisticsAgents",JS_RUNNING)
        statistics_main_agents
        jstatus("Statistics.StatisticsAgents",JS_PENDING)
      rescue => e
        jstatus("Statistics.StatisticsAgents",JS_ERROR)
        STDERR.puts e.message
      end      
    end
    
    if jstart?("Statistics.StatisticsKeywords")
      begin
        jstatus("Statistics.StatisticsKeywords",JS_RUNNING)
        statistics_main_keywords
        jstatus("Statistics.StatisticsKeywords",JS_PENDING)
      rescue => e
        jstatus("Statistics.StatisticsKeywords",JS_ERROR)
        STDERR.puts e.message
      end 
    end
    
    if jstart?("Tool.CleanupTemporaryTable")
      begin
        jstatus("Tool.CleanupTemporaryTable",JS_RUNNING)
        AmiTool.clean_temp_map_table
        jstatus("Tool.CleanupTemporaryTable",JS_PENDING)
      rescue => e
        jstatus("Tool.CleanupTemporaryTable",JS_ERROR)
        STDERR.puts e.message
      end 
    end
    
    if jstart?("Tool.CleanupStatusLog")
      begin
        jstatus("Tool.CleanupStatusLog",JS_RUNNING)
        AmiTool.cleaning_status_log_table
        jstatus("Tool.CleanupStatusLog",JS_PENDING)
      rescue => e
        jstatus("Tool.CleanupStatusLog",JS_ERROR)
        STDERR.puts e.message
      end 
    end
  
    if jstart?("Tool.RepairUserNoneRole")
      begin
        jstatus("Tool.RepairUserNoneRole",JS_RUNNING)
        AmiTool.update_none_role_to_agent
        jstatus("Tool.RepairUserNoneRole",JS_PENDING)
      rescue => e
        jstatus("Tool.RepairUserNoneRole",JS_ERROR)
        STDERR.puts e.message
      end       
    end
  
    if jstart?("Log.BackupOperationLog")
      begin
        jstatus("Log.BackupOperationLog",JS_RUNNING)
        AmiLog.auto_backup_log
        jstatus("Log.BackupOperationLog",JS_PENDING)
      rescue => e
        jstatus("Log.BackupOperationLog",JS_ERROR)
        STDERR.puts e.message
      end  
    end
    
    STDOUT.puts "[Scheduler] daily finished at #{Time.new}"    
  end
  
  def weekly_list
    STDOUT.puts "[Scheduler] weekly started at #{Time.new}"

    if false #jstart?("VoiceLog.RemoveUnknownVoiceLog")
      begin
        jstatus("VoiceLog.RemoveUnknownVoiceLog",JS_RUNNING)
        AmiVoiceLog.remove_unknown_voicelogs_counter
        jstatus("VoiceLog.RemoveUnknownVoiceLog",JS_PENDING)
      rescue => e
        jstatus("VoiceLog.RemoveUnknownVoiceLog",JS_ERROR)
        STDERR.puts e.message
      end
    else
      jstatus("VoiceLog.RemoveUnknownVoiceLog",JS_STOP)
    end
    
    if jstart?("VoiceLog.RepairVoiceLogCounter")
      begin
        jstatus("VoiceLog.RepairVoiceLogCounter",JS_RUNNING)
        AmiVoiceLog.repair_voice_log_counters_weekly
        jstatus("VoiceLog.RepairVoiceLogCounter",JS_PENDING)
      rescue => e
        jstatus("VoiceLog.RepairVoiceLogCounter",JS_ERROR)
        STDERR.puts e.message
      end
    end
  
    if jstart?("Statistics.WeeklyStatistics")
      begin
        jstatus("Statistics.WeeklyStatistics",JS_RUNNING)
        statistics_weekly_repair
        jstatus("Statistics.WeeklyStatistics",JS_PENDING)
      rescue => e
        jstatus("Statistics.WeeklyStatistics",JS_ERROR)
        STDERR.puts e.message
      end
    end
  
    STDOUT.puts "[Scheduler] weekly finished at #{Time.new}"    
  end
  
  def jstart_stop_job(name,state)
    jstatus(name,state)  
  end
  
  protected
  
  def jstatus(name,state)
    js = JobScheduler.where(:name => name).first
    unless js.nil?
      js.update_attributes(:state => state, :updated_at => Time.new.strftime("%Y-%m-%d %H:%M:%S"))
    end
  end
  
  def jstart?(name)
    js = JobScheduler.where(:name => name).first
    return (js.state != JS_STOP)
  end
  
  def jlist
    
    list = []
    list << { :name => "Tool.VoiceLogSwitcher",           :run => "Mintuely" }
    list << { :name => "Tool.VerifyVoiceLogTable",        :run => "Daily" }
    list << { :name => "Tool.CleanupTemporaryTable",      :run => "Daily" }
    list << { :name => "Tool.CleanupStatusLog",           :run => "Daily" }
    list << { :name => "Tool.RepairUserNoneRole",         :run => "Daily" }
    list << { :name => "Tool.DatabaseSyncer",             :run => "Hourly" }
    list << { :name => "Log.BackupOperationLog",          :run => "Daily" }
    list << { :name => "VoiceLog.RepairVoiceLogCounter",  :run => "Daily,Weekly" }
    list << { :name => "VoiceLog.RemoveUnknownVoiceLog",  :run => "Weekly" }
    list << { :name => "Statistics.DailyStatistics",      :run => "Daily" }
    list << { :name => "Statistics.StatisticsAgents",     :run => "Daily" }
    list << { :name => "Statistics.StatisticsKeywords",   :run => "Daily" }
    list << { :name => "Statistics.StatisticsAgentsToday",     :run => "Hourly" }
    list << { :name => "Statistics.StatisticsKeywordsToday",   :run => "Hourly" }	
    list << { :name => "Statistics.WeeklyStatistics",     :run => "Weekly" }
    
    return list
    
  end
  
  def jmklist
    
     list = jlist
     
     list.each do |l|
      job_scheduler = { :name => l[:name], :desc => l[:run] }       
      js = JobScheduler.where(:name => l[:name]).first
      if js.nil?
        job_scheduler[:state] = JS_DEFAULT
        js = JobScheduler.new(job_scheduler)
        js.save
      else
        js.update_attributes(job_scheduler)
      end
     end
     
  end
  
end