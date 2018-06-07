module AnalyticTrigger
  class Server
    
    #
    # main class to initial and start application
    # input: read task from aohsdb.speech_recognition_tasks
    # process: pass data to analytic server (engine)
    # output: save result to db and es
    #
    
    # constants
    
    DELAY_PROCESS = 0.5
    N_OF_THREAD = 2
    N_OF_NOTIFY_THREAD = 4
    
    # start the application
    
    def self.run
      server = new
      server.run
    end
    
    ##
    
    def initialize
      prepare_server
    end
     
    def run
      @workers = []
      @taskqueue = Queue.new
      
      AnalyticTrigger.logger.info "Creating application threads"
      
      # load task to queue
      @workers << Thread.new do
        begin
          AnalyticTrigger.logger.info "Thread for manage jobs started."
          thread_load_task
        rescue => e
          AnalyticTrigger.logger.error e.message
        end
      end
      
      # process task
      N_OF_THREAD.times do 
        @workers << Thread.new do
          begin
            AnalyticTrigger.logger.info "Thread for process jobs started."
            thread_process_task
          rescue => e
            AnalyticTrigger.logger.error e.message
          end
        end
      end
      
      # notification tasks
      N_OF_NOTIFY_THREAD.times do 
        @workers << Thread.new do
          begin
            AnalyticTrigger.logger.info "Thread for notification started."
            thread_notify
          rescue => e
            AnalyticTrigger.logger.error e.message
          end
        end
      end
      
      @workers.map(&:join)
    end
    
    private
    
    def thread_load_task
      loop do
        if @taskqueue.empty? or @taskqueue.length <= N_OF_THREAD + 1
          tasks = AnaTask.fetch_tasks
          tasks.each do |t|
            @taskqueue.push(t)
          end
        end
        sleep DELAY_PROCESS
      end
    end
    
    def thread_process_task
      loop do
        unless @taskqueue.empty?
          task = @taskqueue.pop
          process_task(task)
        else
          sleep DELAY_PROCESS
        end
      end
    end
    
    def thread_notify
      NotificationReceiver.run
    end
    
    def process_task(task)
      unless task.voice_log.nil?
        task.log :info, "found new task - #{task.voice_log.call_id}"
        
        begin
          AutoTaggingCall.run(task)
        rescue => e
          AnalyticTrigger.logger.error e.message
          AnalyticTrigger.logger.error e.backtrace.inspect 
        end
        
        begin
          AutoSummarization.run(task)
        rescue => e
          AnalyticTrigger.logger.error e.message
          AnalyticTrigger.logger.error e.backtrace.inspect 
        end
        
      end
    end
    
    def prepare_server
      # print info
      AnalyticTrigger.logger.info "\n\n"
      AnalyticTrigger.logger.info "Application: SpeechAnalytic Task Trigger"
      AnalyticTrigger.logger.info "Version: #{VERSION}"
      AnalyticTrigger.logger.info "Author: Amivoice Thai"
      # init
      AnalyticTrigger.logger.info "Preparing server environments ..."
      load_rails_configuration
      setup_database_connection
      setup_es_connection
      display_options
      load_mod_data
    end
    
    def load_rails_configuration
      AnalyticTrigger.logger.info " -> Loading configurations ..."
      conf_file = Resource.web_configuration_files
      Config.load_and_set_settings(Config.setting_files(conf_file[:default], conf_file[:local]))
      Settings.add_source!(conf_file[:default])
      Settings.reload!
      if File.exists?(conf_file[:local])
        Settings.add_source!(conf_file[:local])
        Settings.reload!
      end
    end
    
    def load_mod_data
      AutoTaggingCall.init
    end
    
    def setup_database_connection
      db_conf = {
        adapter: Settings.server.database.adapter,
        host: Settings.server.database.hostname,
        database: Settings.server.database.dbname,
        username: Settings.server.database.username,
        password: Settings.server.database.password,
        pool: 5,
        reconnect: true,
        timeout: 60,
        encoding: 'utf8'
      }
      AnalyticTrigger.logger.info " -> Setup database connection ..."
      ActiveRecord::Base.establish_connection(db_conf)
    end
    
    def setup_es_connection
      AnalyticTrigger.logger.info " -> Setup elasticsearch connection ..."
    end
    
    def display_options
      settings = Settings.server.analytic
      settings.each do |s|
        AnalyticTrigger.logger.info " -> #{s.inspect}"
      end
    end
    
    # end class server
  end
end

AnalyticTrigger::Server.run