module AnalyticTrigger
  class AnaTask
    
    COMPLETE_CHANNEL_COUNT = 2
    MAX_READ_TRANSACTION = 10
    
    def self.fetch_tasks
      # select task from table which is channel_count = completed_count
      # or it was created 15 mintues ago
      tasks = []
      cut_time = (Time.now - 15.minutes).strftime("%Y-%m-%d %H:%M:00")
      sql =  "SELECT * FROM speech_recognition_tasks "
      sql << "GROUP BY voice_log_id HAVING COUNT(0) >= #{COMPLETE_CHANNEL_COUNT} OR MAX(created_at) <= '#{cut_time}' "
      sql << "LIMIT #{MAX_READ_TRANSACTION}"
      begin
        result = SqlClient.select_all(sql)
        tasks = result.map { |t| parse(t) }
      rescue => e
        AnalyticTrigger.logger.error e.message
      end
      return tasks
    end
    
    def self.parse(params)
      new(params)
    end
    
    def initialize(params)
      @params = params
      @voice_log = nil
      do_init
    end
    
    def voice_log
      @voice_log
    end
    
    def log(type, message)
      write_log(message, type)
    end
    
    def logkls(kls, type, message)
      write_log(message, type, kls)
    end
    
    private
    
    def write_log(message, type, kls=nil)
      if kls.nil?
        msg = "(#{@voice_log.id}) #{message}"
      else
        msg = "(#{kls} - #{@voice_log.id}) #{message}"
      end
      case type
      when :error
        AnalyticTrigger.logger.error msg
      when :debug
        AnalyticTrigger.logger.debug msg
      else
        AnalyticTrigger.logger.info msg
      end
    end
    
    def do_init
      get_voice_logs
      remove_from_tasklist
    end
    
    def get_voice_logs
      @voice_log = VoiceLog.minimum_select.where(id: @params["voice_log_id"]).first
    end
    
    def remove_from_tasklist
      sql = "DELETE FROM speech_recognition_tasks WHERE voice_log_id = '#{@params["voice_log_id"]}' LIMIT 5;"
      SqlClient.delete(sql)
    end
    
    # end class
  end
end