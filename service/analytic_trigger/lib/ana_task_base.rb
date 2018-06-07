module AnalyticTrigger
  class AnaTaskBase

    def initialize(task, opts={})
      @task = task
      @opts = opts
    end
    
    private

    def process_record?(xopts={})
      if (not defined? @task) or @task.nil?
        log :warn, "rejected - null task"
        return false
      end    
      if (not defined? @task.voice_log) or @task.voice_log.nil?
        log :warn, "rejected - null voice_log"
        return false
      end
      if @task.voice_log.start_time.nil?
        log :warn, "rejected - start_time is null"
        return false
      end
      if @task.voice_log.duration.to_i <= 1
        log :warn, "rejected - null or zero duration"
        return false
      end
      
      log :info, "accepted task to process result"
      #log :info, "  start-time : #{@task.voice_log.start_time.strftime("%Y-%m-%d %H:%M:%S")}"
      #log :info, "   end-stime : #{(@task.voice_log.start_time + @task.voice_log.duration).strftime("%Y-%m-%d %H:%M:%S")}"
      #log :info, "    duration : #{@task.voice_log.duration}"
      #log :info, "    ani/dnis : #{@task.voice_log.ani} / #{@task.voice_log.dnis}"
      return true
    end
    
    def enable?
      begin
        return process_enable
      rescue
        return false
      end
    end
    
    def http_request_timeout
      begin
        return Settings.server.analytic.request_timeout
      rescue
        return 120
      end
    end
    
    def log(type, message)
      klsname = self.class.name.split("::").last
      msgs = message
      unless message.is_a?(Array)
        msgs = [message]
      end
      msgs.each do |msg|
        @task.logkls klsname, type, msg
      end
    end
    
  end
end