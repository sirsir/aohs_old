module AnalyticTrigger
  class AutoSummarization < AnaTaskBase
    
    def self.run(task, opts={})
      xtask = new(task, opts)
      return xtask.run
    end
    
    def run
      if enable? and process_record? and ready?
        data = AnaTaskResult.get_result(process_options)
        log :info, data.messages
        unless data.raw_result.nil?
          update_result(parse_raw_result(data.raw_result))
        end
      end
    end
    
    private
    
    def parse_raw_result(data)
      # choose first element - array result
      tdata = (data.is_a?(Array) ? data.first : data)
      # remove blank/null/empty value
      ddata = tdata.delete_if { |k,v| v.nil? or v.empty? }
      
      tdata = mapping_and_clean_result(tdata)
      return tdata
    end

    def mapping_and_clean_result(data)
      tdata = data
      return tdata
    end
    
    def update_result(data)
      log :info, "updating result: #{data.inspect}"
      begin
        ves = ElsClient::VoiceLogDocument.new(@task.voice_log.id)
        if ves.created?
          ves.update_auto_taggings(data)
          update_taggings(data)
        end
      rescue => e
        log :error, e.message
      end
    end
    
    def update_taggings(data)
      data.each do |tag_type, value|
        t = Tag.where(name: value).order(id: :desc).first
        unless t.nil?
          tag = Tagging.where(
              tag_id: t["id"],
              tagged_id:  @task.voice_log.id
          ).first_or_create
        end
      end
    end
    
    def process_options
      options = {
        url: URI.join(process_url).to_s,
        timeout: http_request_timeout,
        params: {
          voice_log_ids: [@task.voice_log.id]
        }
      }
      return options
    end
    
    def process_url
      return Settings.server.analytic.auto_summarization.url
    end
    
    def process_enable
      return Settings.server.analytic.auto_summarization.enable
    end
    
    def ready?
      return true
    end
        
  end
end