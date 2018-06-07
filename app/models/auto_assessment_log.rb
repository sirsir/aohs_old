class AutoAssessmentLog < ActiveRecord::Base
  
  serialize :result_log, JSON
  
  def self.get_assessment_logs(voice_log_id)
    select = [:assessment_logs]
    voice_log = VoiceLogsIndex::VoiceLog.query(term: { id: voice_log_id }).limit(1)
    voice_log = voice_log.only(select)
    begin
      original_data = voice_log.to_a.first.assessment_logs
    rescue => e
      #Rails.logger.error "Failed get assessment logs from ES. #{e.message}"
      original_data = nil
    end
    return original_data
  end
  
  def get_detected_info
    @detected_info = {}
    unless self.result_log.nil?
      get_summary_info 
      get_detected_segments
      get_talking_speeds
    end
    return @detected_info
  end
  
  def set_asst_logs(asst_logs)
    @asst_logs = asst_logs
    unless @asst_logs.nil?
      log = (@asst_logs.select { |l|
        l["evaluation_question_id"].to_i == self.evaluation_question_id.to_i and l["evaluation_plan_id"].to_i == self.evaluation_plan_id.to_i
      }).first
      unless log.nil?
        self.result_log = log.to_json
      end
    end
  end
  
  def result_label
    self.result  
  end
  
  private
  
  def result_data
    unless defined? @result_data
      begin
        unless self.result_log.nil?
          if self.result_log.is_a?(String)
            @result_data = JSON.parse(self.result_log)
          else
            @result_data = self.result_log
          end
        end
      rescue => e
        Rails.logger.error e.message
      end
    end
    @result_data
  end
  
  def get_summary_info
    result = result_data["comment"]
    unless result.nil?
      @detected_info[:brief_summary] = result
    end
  end
  
  def get_detected_segments
    result = result_data["debug_result"]
    if not result.nil? and result.is_a?(Array) 
      data = {}
      result.each do |da|
        db = da
        #unless da.nil?          
          #da.each do |db|
            dkey = db["voice_log_id"].to_s
            if data[dkey].nil?
              v = VoiceLog.select([:id, :start_time]).where(id: db["voice_log_id"]).first
              data[dkey] = { voice_log_id: db["voice_log_id"].to_i, call_time: v.start_time.strftime("%Y-%m-%d %H:%M"), sentences: [] }
            end
            time_tag = db["timing"]
            #text = StringFormat.sentense_format(db["sentence"])
            text = StringFormat.sentense_format(db["sentence_highlight"])
            data[dkey][:sentences] << {
              voice_log_id: db["voice_log_id"].to_i,
              text: text,
              stime: time_tag["start_msec"].to_i/1000.0,
              etime: time_tag["end_msec"].to_i/1000.0,
              dsptime: StringFormat.format_sec(time_tag["start_msec"].to_i/1000.0)
            }
          #end
        #end
      end
      @detected_info[:matched_sentenses] = []
      data.each do |k, v|
        @detected_info[:matched_sentenses] << v
      end
      @detected_info[:matched_sentenses] = @detected_info[:matched_sentenses].sort { |a,b| a[:stime] <=> b[:stime] }
    end
  end
    
  def get_talking_speeds
    result = result_data["speak_rate"]
    unless result.nil?
      begin
        @detected_info[:matched_sentenses] = []
        overtalk = result["over_talks"]
        overtalk.each do |ov|
          @detected_info[:matched_sentenses] << {
            text: StringFormat.sentense_format(ov["utterance"]),
            ssec: ov["start_msec"].to_i/1000.0,
            esec: nil,
            wpm_rate: ov["talk_rate"].to_i
          }
        end
      rescue => e
        Rails.logger.error e.message
      end
    end
  end
  
  
  #def get_silence
  #  slient_time = find_log("slient_time")
  #  unless slient_time.nil?
  #    slient_time = slient_time.first
  #    @detected_info[:messages] << "Max slient #{slient_time["max_slient_time"]} secs"
  #  end
  #end
  
  #def get_talking_speed
  #  #rate = find_log("speak_rate")
  #  #unless rate.nil?
  #  #  @detected_info[:messages] << "Max speed #{rate.first.to_i} words/min"
  #  #end
  #end
  #
  #def get_times
  #  #data = find_log("timing")
  #  #if not data.nil? and not data.empty?
  #  #  st, et = -1, -1
  #  #  data.each do |d|
  #  #    st = d["start_msec"].to_i if d["start_msec"].to_i >= st or st == -1
  #  #    et = d["end_msec"].to_i if d["end_msec"].to_i <= et or et == -1
  #  #  end
  #  #  if st >= 0 and et > 0
  #  #    @detected_info[:time_tags] = [{ ssec: st/1000.0, esec: et/1000.0 }]
  #  #  end
  #  #end
  #end
  #
  #def matching_info
  #  #data = find_log("timing")
  #  #if not data.nil? and not data.empty?
  #  #  st, et = 0, 0
  #  #  data.each do |d|
  #  #    #if d["start_msec"]/1000 > et
  #  #      st = d["start_msec"].to_i/1000
  #  #      et = d["end_msec"].to_i/1000
  #  #      @detected_info[:messages] << et.to_s #{ ssec: st, esec: et, title: self.evaluation_question_id }
  #  ##    #end
  #  #  end
  #  #end
  #end
  #
  #def find_log(key)
  #  log = self.result_log
  #  log.extend Hashie::Extensions::DeepFind
  #  return log.deep_find_all(key)
  #end
  
end
