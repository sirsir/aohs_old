module AnalyticTrigger
  class AutoTaggingCall < AnaTaskBase
    
    SILT_TAG = "Silent"
    
    def self.run(task, opts={})
      xtask = new(task, opts)
      return xtask.run
    end
    
    def self.init
      @@exc_regexp = []
      @@exc_unness = []
      msfile = File.join(APP_DATA,"sentense.ivr-message.txt")
      File.open(msfile).each do |line|
        next if line.blank? or line =~ /^#/
        txs = line.chomp.strip.split("|")
        tnm = txs.shift
        trp = (txs.map{ |x| "(#{x})"}).join(".*")
        @@exc_regexp << {
          tag: tnm,
          regexp: Regexp.new("^.*#{trp}.*")
        }
      end
      msfile = File.join(APP_DATA,"sentense.unnessary.txt")
      File.open(msfile).each do |line|
        next if line.blank? or line =~ /^#/
        @@exc_unness << line.chomp.strip
      end
    end
    
    def run
      result_tags = []
      if ready? and (not null_voice_log?)
        if @task.voice_log.duration <= 1
          result_tags << SILT_TAG
        else
          if init_transcription_data?
            if no_speech_result?
              result_tags << SILT_TAG
            end
          else
            # no-data
          end
        end
        update_result(result_tags)
      end
    end
    
    private
    
    def init_transcription_data?
      ves = ElsClient::VoiceLogDocument.new(@task.voice_log.id)
      if ves.exists?
        doc = ves.get_document
        unless doc.nil?
          @ds_transcriptions = []
          lprev_text = ""
          lindex = 0
          rprev_text = ""
          rindex = 0
          unless doc.recognition_results.nil?
            doc.recognition_results.sort{ |a,b| a["start_msec"] <=> b["start_msec"] }.each do |t|
              t_result = t["result"].to_s.gsub(/\s+/,"")
              next if @@exc_unness.include?(t_result)
              @ds_transcriptions << {
                index: ((t["channel"].to_i == 0) ? lindex : rindex),
                channel: t["channel"].to_i,
                pre_result: ((t["channel"].to_i == 0) ? lprev_text : rprev_text),
                result: t_result,
                length: t_result.length
              }
              if t["channel"] == 0
                lprev_text = t_result
                lindex += 1
              else
                rprev_text = t_result
                rindex += 1
              end
            end
          end
          return true
        end
      end
      return false
    end
    
    def no_speech_result?
      
      dsr_count = @ds_transcriptions.length
      
      # no dsr result
      if dsr_count <= 1
        return true
      end
      
      # have many short segments > 80%
      lch_count = @ds_transcriptions.count{ |x| x[:channel].to_i == 0 and x[:length] <= 10 }
      rch_count = @ds_transcriptions.count{ |x| x[:channel].to_i == 1 and x[:length] <= 10 }
      if (lch_count + rch_count) >= (dsr_count * 0.8)
        return true
      end
      
      # have single channel
      lch_count = @ds_transcriptions.count{ |x| x[:channel].to_i == 0 }
      rch_count = @ds_transcriptions.count{ |x| x[:channel].to_i == 1 }
      if rch_count <= 0 or lch_count <= 0
        return true
      end
      
      # match reject message at begining of call
      found_msg = false
      if rch_count <= 6 and lch_count <= 6
        @ds_transcriptions.each do |trx|
          next if trx[:length] <= 3
          @@exc_regexp.each do |reg|
            if reg[:regexp].match(trx[:pre_result] + trx[:result])
              found_msg = true
              break
            end
          end
          break if found_msg
        end
        if found_msg
          return found_msg
        end
      end
      
      return false
    end
    
    def null_voice_log?
      return @task.voice_log.nil?  
    end
    
    def update_result(result_tags)
      log :info, "call-tags=#{result_tags.join(", ")}"
      try_cnt = 0
      e_msg = nil
      while try_cnt < 3
        begin
          updated_cates = @task.voice_log.update_call_categories(result_tags)
          log :info, "updated-tags count=#{updated_cates.length}"
          try_cnt = 99
        rescue => e
          e_msg = e.message
          try_cnt += 1
          sleep(1)
        end
      end
      if try_cnt >= 99
        log :info, "can not update tags, #{e_msg}"
      end
    end
    
    def ready?
      return true
    end
        
  end
end