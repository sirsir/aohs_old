module AnalyticTrigger
  class CallJourney
    
    def self.update(task, opts={})
      xtask = new(task, opts)
      return xtask.update
    end
    
    def initialize(task, opts={})
      @task = task
      @opts = opts
    end

    def update
      if enable? and proceed?
        log :info, "trying to process result"
        data = AnaTaskResult.get_result(pass_options)
        data.messages.each do |msg|
          log :info, msg
        end
        unless data.raw_result.nil?
          update_result(parse_result(data.raw_result))
        end
      end
    end
    
    private

    def proceed?
      if @task.voice_log.duration <= 1
        return false
      end
      return true
    end

    def pass_options
      options = {
        url: Settings.server.analytic.journey.url,
        timeout: Settings.server.analytic.journey.timeout,
        params: {
          voice_log_ids: [@task.voice_log.id]
        }
      }
      return options
    end
    
    def parse_result(raw)
      output_dialogs = []
      unless raw.empty?
        raw = raw.sort { |a,b| a["start_msec"] <=> b["start_msec"] }
        raw.each_with_index do |r,i|
          next if r["category"].downcase == "unknown"
          output_dialogs << {
            label: r["category"],
            start_msec: r["start_msec"].to_i,
            end_msec: r["end_msec"].to_i
          }
        end
        log :info, "result: #{output_dialogs.to_json}"    
      end
      return output_dialogs
    end
    
    def update_result(data)
      # update es
      log :info, "trying update result to es/logs"
      begin
        ves = ElsClient::VoiceLogDocument.new(@task.voice_log.id)
        if ves.created?
          ves.update_dialog_logs(data)
        end
      rescue => e
        log :error, e.message
      end
    end
    
    def log(type, message)
      @task.logkls :journey, type, message
    end

    def enable?
      return Settings.server.analytic.journey.enable
    end
    
  end
end