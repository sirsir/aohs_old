module HousekeepingData
  class Base
    
    def initialize(options={})
      @options = parse_options(options)
    end
    
    def options
      @options
    end
    
    def errors
      @errors
    end
    
    private
    
    def parse_options(options)
      new_options = {
        today: Date.today,
        yesterday: Date.today - 1
      }
      
      if options.has_key?("date")
        new_options[:target_date] = Date.parse(options["date"])
      end
      
      if options.has_key?("clean")
        new_options[:force_clean] = options["clean"]
      end
      
      if options.has_key?("compact")
        new_options[:force_compact] = options["compact"]
      end
      
      logger.info "starting to housekeeping data"
      logger.info "process name: #{self.class.name}"
      logger.info "input options: #{options.inspect}"
      logger.info "accepted options: #{new_options.inspect}"
      
      return new_options
    end
    
    def logger
      SysLogger.logger  
    end
    
    def task
      ScheduleInfo
    end
    
  end
end
