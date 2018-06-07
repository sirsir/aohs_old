module AnalyticTrigger
  class CallClassify
    
    def self.update(task, opts={})
      xtask = new(task, opts)
      return xtask.update
    end
    
    def initialize(task, opts={})
      @task = task
      @opts = opts
    end
    
    def update
      if enable?
        data = AnaTaskResult.get_result(pass_options)
        data.messages.each do |msg|
          log :info, msg
        end
        
        unless data.raw_result.nil?
           
        end
      end
    end
    
    def pass_options
      options = {
        url: Settings.server.analytic.call_type.url,
        timeout: Settings.server.analytic.call_type.timeout
      }
      options[:params] = {
        call_type: [],
        name_list: true
      }
      options[:url] = Settings.server.analytic.call_type.url + @task.voice_log.id.to_s
      return options
    end
    
    private
    
    def log(type, message)
      @task.logkls :classify, type, message
    end
    
    def enable?
      return Settings.server.analytic.call_type.enable
    end
    
  end
end