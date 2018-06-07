module AppUtils
  class SpeechTaskCreator
    
    def self.create(options)
      task = new(options)
      task.create
    end
    
    def initialize(options)
      @options = options  
    end
    
    def create
      log "Options: #{@options.inspect}"
      docreate = false
      params = {}
      
      if @options[:date].present?
        begin
          params[:date] = Date.parse(@options[:date])
          docreate = true
        rescue => e
          log e.message
        end
      end
      
      if @options[:id].present?
        begin
          id = @options[:id].to_i
          docreate = true if id > 0
          params[:id] = id
        rescue => e
          log e.message
        end
      end
      
      if @options[:all].present?
        docreate = true
      end
      
      if @options[:system_id].present?
        begin
          params[:system_id] = @options[:system_id].to_i
        rescue => e
          log e.message
          docreate = false
        end
      end
      
      if @options[:site_id].present?
        begin
          params[:site_id] = @options[:site_id].to_i
        rescue => e
          log e.message
          docreate = false
        end        
      end
      
      if @options[:limit].to_i > 0
        params[:limit] = @options[:limit].to_i  
      end
      
      if docreate
        create_task(params)
      end
    end
    
    def create_task(params)
      log "Searching voice logs data with params #{params.inspect}"
      
      voice_log = VoiceLog
      if params[:id].present?
        voice_log = voice_log.where(id: params[:id])  
      end
      
      if params[:date].present?
        voice_log = voice_log.at_date(params[:date])  
      end
      
      if params[:system_id].present?
        voice_log = voice_log.where(system_id: params[:system_id])
      end
      
      if params[:site_id].present?
        voice_log = voice_log.where(site_id: params[:site_id])
      end

      if params[:limit].present? and params[:limit].to_i > 0
        voice_log = voice_log.limit(params[:limit])
      end
      
      total_rec = voice_log.count(0)
      log "Total Record: #{total_rec}"
      if total_rec > 0
        voice_log.each do |vl|
          log "Create task #{vl.id}"
          inf = {
            voice_log_id: vl.id,
            call_id: vl.call_id,
            start_time: vl.start_time.to_formatted_s(:db),
            created_at: Time.now.to_formatted_s(:db)
          }
          [1,2].each do |chn|
            tsk = SpeechRecognitionTask.new(inf)
            tsk.channel_no = chn
            tsk.save
          end
        end
      end
      
      log "Done."
    end
    
    def log(msg)
      STDOUT.puts msg  
    end
    
  end
end