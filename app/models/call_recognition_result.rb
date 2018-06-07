class CallRecognitionResult

  DEFAULT_DIALOG_NAME = 'other'
  MIN_DIALOG_MSEC = 0
  
  def self.get_detail(voice_log_id, select=[])
    crr = new(voice_log_id, select)
    return crr
  end
  
  def initialize(voice_log_id, select=[])
    @voice_log_id = voice_log_id.to_i
    @select_data = select
    
    retrive_data_from_es
    mapped_result
  end
  
  def transcriptions
    @transcriptions
  end
  
  def dialogs
    @dialogs_detail
  end
  
  def grouped_dialogs
    @dialogs_all
  end
  
  def detected_keywords
    @detected_keywords  
  end
  
  def note
    @note
  end
  
  def stats
    @stats  
  end
  
  private
  
  def mapped_result
    @dialogs_detail, @dialogs_all = mapped_dialog_result
    @transcriptions = mapped_transcription_result
    @stats = mapped_stats_result
    @detected_keywords = mapped_d_keywords
    @note = get_note_from_auto_tag
  end  
  
  def retrive_data_from_es
    select = [
      :recognition_results, :dialog_results,
      :recognizer_stats, :keyword_results,
      :edited_transcriptions
    ]
    unless @select_data.empty?
      select = @select_data
    end
    begin
      @original_data = nil
      if Settings.server.es.enable == true
        voice_log = VoiceLogsIndex::VoiceLog.query(term: { id: @voice_log_id }).limit(1)
        voice_log = voice_log.only(select)
        @original_data = voice_log.to_a.first
      end
    rescue => e
      Rails.logger.error "Error to get data from ES. #{e.message}"
      @original_data = nil
    end
  end
  
  def mapped_transcription_result
    begin
      orgtrans = @original_data.recognition_results
    rescue
      orgtrans = []
    end
    begin
      editedtrans = @original_data.edited_transcriptions
    rescue
      editedtrans = []
    end
    output = []
    
    if not orgtrans.nil? and not orgtrans.empty?
      dialogs, dialogs_group = mapped_dialog_result
      orgtrans.each do |tran|
        t = tran
        x = {}
        x['start_msec'] = x_to_msec(t["start_msec"])
        x['start_sec']  = msec_to_sec(t["start_msec"])
        x['end_msec']   = x_to_msec(t["end_msec"])
        x['end_sec']    = msec_to_sec(t["end_msec"])
        x['duration_sec'] = x['end_msec'] - x['start_sec']
        x['channel']    = t["channel"].to_i
        x['channel_no'] = t["channel"].to_i
        x['result']     = t["result"].strip
        x['speaker_type'] = t["speaker_type"]
        x['speaker_id'] = t["speaker_id"].to_i
        x['speaker_type_name'] = speaker_type_name(t["speaker_type"])
        x['dialog_name'] = get_dialog_name(x, dialogs)
        # replace with edited text
        etrx = editedtrans.select { |trx| trx["start_msec"] == x["start_msec"] and trx["channel"] == x["channel"] }
        unless etrx.empty?
          etrx = etrx.first
          x['org_result'] = compact_result(x['result'])
          x['result'] = compact_result(etrx['text'])
          x['edited_flag'] = 'yes'
        else
          x['org_result'] = compact_result(x['result'])
        end
        output << Hashie::Mash.new(x)
      end
      # sort 
      output = output.sort { |a, b| a.start_msec <=> b.start_msec }
      # concat output
      if Settings.callsearch.merge_transcription
        concat_output = []
        tra = output.shift
        while not output.empty?
          trb = output.shift
          time_gap = (tra.end_msec - trb.start_msec).abs
          if tra.channel_no == trb.channel_no and time_gap < 50
            tra.result << " " << trb.result
            tra.end_msec = trb.end_msec
            tra.end_sec = trb.end_sec
            tra.duration_sec = trb.end_sec - tra.start_sec
          else
            concat_output << tra
            tra = trb
          end
        end
        concat_output << tra
        output = concat_output
      end
    end
    
    if Settings.callsearch.masking_sensitive_data
      output = AppUtils::TextMasking.masking_conversation(output)
    end
    return output
  end
    
  def mapped_dialog_result
    begin
      orgdia = @original_data.dialog_results
    rescue
      orgdia = []
    end
    output = []
    dialog_group = []
    
    duration = VoiceLog.select(:duration).where(id: @voice_log_id).first.duration rescue 0
    duration = duration.to_i
    duration_msec = duration * 1000.0
    
    unless orgdia.empty?
      orgdia = orgdia.sort { |a,b| a["start_msec"] <=> b["start_msec"] }
      prev_end_msec = 0
      orgdia.each do |dia|
        d = dia
        x = {}
        x['start_msec'] = x_to_msec(d["start_msec"])
        x['start_sec']  = msec_to_sec(d["start_msec"])
        x['end_msec']   = x_to_msec(d["end_msec"])
        x['end_sec']    = msec_to_sec(d["end_msec"])
        x['label']      = d["label"].strip
        if (prev_end_msec - x['start_msec']).abs > MIN_DIALOG_MSEC
          s_msec = prev_end_msec.to_i + 1 
          e_msec = x['start_msec'] - 1
          y = {}
          y['start_msec'] = x_to_msec(s_msec)
          y['start_sec']  = msec_to_sec(s_msec)
          y['end_msec']   = x_to_msec(e_msec)
          y['end_sec']    = msec_to_sec(e_msec)
          y['label']      = DEFAULT_DIALOG_NAME
          output << Hashie::Mash.new(y)
        end
        output << Hashie::Mash.new(x)
        prev_end_msec = x['end_msec']
      end
      if (prev_end_msec - duration_msec).abs > MIN_DIALOG_MSEC
        s_msec = prev_end_msec.to_i + 1 
        e_msec = duration_msec
        y = {}
        y['start_msec'] = x_to_msec(s_msec)
        y['start_sec']  = msec_to_sec(s_msec)
        y['end_msec']   = x_to_msec(e_msec)
        y['end_sec']    = msec_to_sec(e_msec)
        y['label']      = DEFAULT_DIALOG_NAME
        output << Hashie::Mash.new(y)
      end
      output = output.sort { |a,b| a["start_msec"] <=> b["start_msec"] }
      # grouping
      output.each do |dia|
        idx = dialog_group.index { |o| o['label'] == dia['label'] }
        if idx.nil?
          dialog_group << { "label" => dia['label'], "timetags" => [] }
          idx = dialog_group.length - 1
        end
        dialog_group[idx]['timetags'] << {
          "start_msec" => dia["start_msec"],
          "display_time" => StringFormat.format_sec(msec_to_sec(dia["start_msec"]))
        }
      end
    end
    
    return output, dialog_group
  end
  
  def mapped_stats_result
    begin
      dstats = @original_data.recognizer_stats
      if dstats.nil?
        dstats = []
      end
    rescue
      dstats = []
    end
    
    outputs = []
    unless dstats.empty?
      dstats.each do |stats|
        channel = stats["channel"].to_i
        if outputs[channel].nil? or outputs[channel]["start_recognize_at"] >= stats["start_recognize_at"]
          outputs[channel] = {
            "channel_name" => channel_name(channel),
            "start_recognize_at" => stats["start_recognize_at"],
            "rt" => stats["rt"].to_f.round(4),
            "utterances_count" => stats["utterances_count"].to_i,
            "dsr_grammar_fname" => stats["dsr_grammar_fname"],
            "dsr_profile_id" => stats["dsr_profile_id"]
          }
        end
      end
    end
    
    return outputs
  end
  
  def get_note_from_auto_tag
    begin
      txt_notes = []
      atags = @original_data.au_taggings
      unless atags.nil?
        txt_notes << atags["result"]
      end
      return txt_notes.join(", ")
    rescue
    end
    return nil
  end
  
  def mapped_d_keywords
    begin
      logs = @original_data.keyword_results
    rescue
      logs = []
    end
    output = []
    if not logs.nil? and not logs.empty?
      logs.each do |r|
        w = {
          start_msec: r["start_msec"].to_i,
          end_msec: r["end_msec"].to_i,
          keyword_id: r["keyword_id"].to_i,
          result: r["result"],
          voice_log_id: 0
        }
        output << ResultKeyword.new(w)
      end
      output = output.sort { |a, b| a.start_msec <=> b.start_msec }
      output = ResultKeyword.result_logs(output)   
    end
    return output
  end
  
  def get_dialog_name(tran, dialogs)
    idx = dialogs.index { |d| d["start_msec"] >= tran["start_msec"] and d["start_msec"] <= tran["end_msec"] }
    if idx.nil?
      idx = dialogs.index { |d| d["end_msec"] >= tran["start_msec"] and d["end_msec"] <= tran["end_msec"] }
    end
    unless idx.nil?
      return dialogs[idx]["label"]
    end
    return DEFAULT_DIALOG_NAME
  end
  
  def channel_name(channel)
    case channel
    when 0
      return "LEFT"
    when 1
      return "RIGHT"
    end
    return "UNKNOWN"
  end
  
  def speaker_type_name(speaker_type)
    case speaker_type
    when 'A', 'U'
      return "Agent"
    when 'C'
      return "Customer"
    end
    return "Unknown"
  end

  def x_to_msec(x)
    return x.to_i
  end
  
  def msec_to_sec(x)
    return (x_to_msec(x)/1000.0).round(3)
  end
  
  def compact_result(txt)
    return txt.to_s.chomp.strip.gsub(/\s+/," ")
  end
  
end