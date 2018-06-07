require 'rubygems'
require 'thor/rails'
require 'json'

module Appl
  
  # default environment to execute thor command
  # RAILS_ENV=production
  
  ENV['RAILS_ENV'] ||= 'production'
  
  #
  # Installation commands
  #
  
  class Install < Thor
    include Thor::Rails
    
    desc "default_data", "initial system data and directory"
    def default_data
      AppUtils.initial_db
      WorkingDir.prepare_dirs
    end
    
    desc "services", "setup system services"
    def services
      AppUtils::InstallService.install
    end
        
    desc "crontab", "update crontab"
    def crontab
      system "whenever --update-crontab"
    end
    
    desc "compile_assets", "compile assets [clean]"
    method_option :clean, type: :boolean
    def compile_assets
      opts = AppUtils::ThorOptionParser.parse(options)
      if opts.is?(:clean)
        WorkingDir.clean_cache    
      end
      system "rake assets:clean RAILS_ENV=production"
      system "rake assets:precompile RAILS_ENV=production"
    end

    desc "create_es_indexs", "create elasticsearch indexs"
    def create_es_indexs
      opts = AppUtils::ThorOptionParser.parse
      [MessageLogsIndex, VoiceLogsIndex].each do |es_index|
        idx_name = es_index.name
        if es_index.exists?
          if opts.confirm?("#{idx_name} has been created. Are you sure to replace?")
            STDOUT.puts "Removing index '#{idx_name}'"
            es_index.delete
          else
            STDOUT.puts "Ignore to delete index '#{idx_name}'"
          end
        end
        unless es_index.exists?
          STDOUT.puts "Creating new index '#{idx_name}'"
          es_index.create
        else
          STDOUT.puts "No create index '#{idx_name}'"
        end
      end
    end
    
    desc "db_views", "update db views"
    def db_views
      sql_files = Dir.glob(File.join(File.dirname(__FILE__).gsub("/lib/thor",""),"db/view","*.view.sql"))
      sql_files.sort.each do |fsql|
        STDOUT.puts "Executing #{File.basename(fsql)}"
        dsql = File.read(fsql).split("--")
        dsql.each do |sql|
          ActiveRecord::Base.connection.execute(sql) 
        end
      end
    end

    desc "db_triggers", "update db triggers"
    def db_triggers
      sql_files = Dir.glob(File.join(File.dirname(__FILE__).gsub("/lib/thor",""),"db/trigger","*.trigger.sql"))
      sql_files.sort.each do |fsql|
        STDOUT.puts "Executing #{File.basename(fsql)}"
        dsql = File.read(fsql).split("--")
        dsql.each do |sql|
          ActiveRecord::Base.connection.execute(sql) 
        end
      end
    end
    
  end
  
  #
  # Statistics Data
  #
  
  class Stats < Thor
    include Thor::Rails
    
    desc "update_phone_counter", "call stats by phonenumber [date|ndays]"
    method_option :date, type: :string, required: false
    method_option :ndays, type: :string, required: false
    def update_phone_counter
      StatsData::DailyRepeatedCallCounter.run(options)
    end

    desc "update_call_statistics", "call stats [date|ndays]"
    method_option :date, type: :string, required: false
    method_option :ndays, type: :string, required: false
    def update_call_statistics
      StatsData::CallAgentStats.run(options)
    end
    
    desc "update_evaluation_stats", "call evaluation stats [date|ndays]"
    method_option :date, type: :string, required: false
    method_option :ndays, type: :string, required: false
    def update_evaluation_stats
      StatsData::QuestionCounter.run(options)
    end

    desc "update_keyword_counter", "keyword stats [date|ndays]"
    method_option :date, type: :string, required: false
    method_option :ndays, type: :string, required: false
    def update_keyword_counter
      StatsData::KeywordCounter.run(options)
    end
    
    desc "update_calendar", "calendar"
    def update_calendar
      StatsData::CalendarMaker.run
    end

    desc "update_table_info", "mysql tables stats"
    def update_table_info
      StatsData::MySQLTableInfo.run
    end
    
    # end stats class
  end
  
  #
  # Maintenance
  #
  
  class Maintenance < Thor

    ENV['RAILS_ENV'] ||= 'production'
    
    include Thor::Rails

    desc 'cleanup_table', 'cleanup table'
    def cleanup_table
      Housekeeping.do_all_tasks
    end
    
    desc 'update_current_computer', 'update latest computer and extension mapping'
    def update_current_computer
      UpdateCurrentComputer.update_all
    end

    desc 'init_current_extension', 'init user extension (initial)'
    def init_current_extension
      UpdateCurrentComputer.init_ext
    end
    
    desc 'auto_increment_voice_log', 'up auto increment id of voice_logs'
    def auto_increment_voice_log
      AppUtils::InitialDb.update_max_voice_log_id
    end
    
    desc 'sync_hangup_call', 'sync hanhup call'
    def sync_hangup_call
      DataSyncer::VoiceLogSyncer::HangupVoiceLog.sync
    end
    
    desc 'sync_voice_logs', 'sync voice_logs'
    method_option :d,  :type => :string,  :required => false
    method_option :date, :type => :string, :required => false
    def sync_voice_logs
      if options[:d] == "yesterday"
        DataSyncer::VoiceLogSyncer::DailyLog.sync_yesterday
      else
        opts = {}
        unless options[:date].blank?
          opts[:date] = Date.parse(options[:date])
        end
        unless options[:d].blank?
          opts[:date] = Date.parse(options[:d])
        end
        DataSyncer::VoiceLogSyncer::DailyLog.sync(opts)
      end
    end

    desc 'housekeep_es_voice_logs', 'hkp docs in elasticsearch'
    method_option :date, type: :string, required: false
    def housekeep_es_voice_logs
      opts = AppUtils::ThorOptionParser.parse(options)
      Housekeeping::HskpEsVoiceLog.run(opts.options)
    end
    
    desc 'housekeep_voice_logs', 'hkp voicelog data in database'
    def housekeep_voice_logs
      Housekeeping::HskpVoiceLog.cleanup_voice_log
    end

    desc 'housekeep_statistic', 'housekeep_statistic'
    def housekeep_statistic
      Housekeeping::HskpStats.cleanup_stats_logs
    end
    
    desc "cleanup_tmpdir", "cleanup temporary directories"
    def cleanup_tmpdir
      WorkingDir::HouseKeeping.cleanup_working_dir
    end
    
    desc "export_voicelog", "process call export tasks"
    def export_voicelog
      ExportVoiceLog::ExecuteTask.run  
    end

    desc "logrotate", "log lotation"
    def logrotate
      AppUtils::LogRotation.run
    end
    
    desc "manfile", "manfile"
    def manfile
      AppUtils::SourceFileChecker.scan_and_update
    end
    
    desc "reset_user_password", "reset user password [all|nopassword|role_id|user_id]"
    method_option :all, type: :string, required: false
    method_option :nopassword, type: :string, required: false
    method_option :role_id, type: :string, required: false
    method_option :user_id, type: :string, required: false
    def reset_user_password
      opts = AppUtils::ThorOptionParser.parse(options)
      AppUtils::UserPasswd.reset_user_password(opts.options)
    end
    
    desc 'assign_tasks', 'perform auto assignment'
    def assign_tasks
      AutoAssignmentTask.run
    end
    
  end

  #
  # Maintain ElasticSearch
  #
  
  class Elastic < Thor
    include Thor::Rails
    
    desc "delete_voicelog_doc", "delete voice log document [date|ndays|id|limit]"
    method_option :date,  :type => :string,  :required => true
    method_option :id,  :type => :string,  :required => false
    method_option :system_id,  :type => :string,  :required => false
    method_option :site_id,  :type => :string,  :required => false
    method_option :limit,  :type => :string,  :required => false
    method_option :ndays, :type => :string, :required => false
    method_option :force_delete, :type => :boolean
    def delete_voicelog_doc
      opts = AppUtils::ThorOptionParser.parse(options)
      if opts.force_delete? or opts.confirm?("Are you sure to delete it?")
        AppUtils::DeleteEsDocument.delete_docs(opts.options)
      end
    end
    
  end
  
  #
  # Maintain Analytic
  #
  
  class Analytics < Thor
    include Thor::Rails

    desc 'create_speech_task', 'create_speech_task'
    method_option :date,  :type => :string,  :required => false
    method_option :id,  :type => :string,  :required => false
    method_option :system_id,  :type => :string,  :required => false
    method_option :site_id,  :type => :string,  :required => false
    method_option :all,  :type => :string,  :required => false
    method_option :limit, :type => :string, :required => false
    def create_speech_task
      AppUtils::SpeechTaskCreator.create(options)
    end
    
  end
  
end
