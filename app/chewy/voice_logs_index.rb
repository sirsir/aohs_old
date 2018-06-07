class VoiceLogsIndex < Chewy::Index
  
  define_type VoiceLog do
    
    # general call information
    field :site_id, type: 'integer'
    field :system_id, type: 'integer'
    field :call_id, type: 'string'
    field :start_time, type: 'date', format: 'yyyy-MM-dd HH:mm:ss', value: ->(voice_log) { voice_log.start_time.strftime("%Y-%m-%d %H:%M:%S") }
    field :extension, type: 'string'
    field :ani, type: 'string'
    field :dnis, type: 'string'
    field :duration, type: 'integer'
    field :call_direction, type: 'string'
    field :agent_id, type: 'integer'

    field :words do
      field :word, type: 'string'
      field :count, type: 'integer'
      field :speaker_type, type: 'string'
    end
    
    # recognition_result / transcriptions
    field :recognition_results do
      field :start_msec, type: 'integer'
      field :end_msec, type: 'integer'
      field :channel, type: 'integer'
      field :speaker_type, type: 'string'
      field :speaker_id, type: 'integer'
      field :result, type: 'string'
    end
    
    # detected keywords
    field :keyword_results do
      field :keyword_id, type: 'integer'
      field :start_msec, type: 'integer'
      field :end_msec, type: 'integer'
      field :channel, type: 'integer'
      field :result, type: 'string'
    end
    
    # recognizer stats
    field :recognizer_stats do
      field :channel, type: 'integer'
      field :speechserver_version, type: 'string'
      field :start_task_at, type: 'date', format: 'yyyy-MM-dd HH:mm:ss'
      field :start_recognize_at, type: 'date', format: 'yyyy-MM-dd HH:mm:ss'
      field :dsr_session_id, type: 'string'
      field :dsr_mode, type: 'string'
      field :dsr_profile_id, type: 'string'
      field :dsr_speed_vs_accuracy, type: 'float'
      field :dsr_grammar_fname, type: 'string'
      field :dsr_server_name, type: 'string'
      field :dsr_segmenter_props, type: 'string'
      field :dsr_volume, type: 'integer'
      field :dsr_snr, type: 'integer'
      field :task_delay_time, type: 'integer'
      field :recognize_preprocess_time, type: 'float'
      field :recognize_process_time, type: 'float'
      field :recognize_postprocess_time, type: 'float'
      field :audio_load_time, type: 'float'
      field :utterances_count, type: 'integer'
      field :sent_byte, type: 'integer'
      field :audio_length, type: 'float'
      field :rt, type: 'float'
    end
    
  end
  
  # type for store desktop activitiy from client
  define_type UserActivityLog do
    field :start_time, type: 'date', format: 'yyyy-MM-dd HH:mm:ss'
    field :duration, type: 'integer'
    field :proc_name, type: 'string'
    field :window_title, type: 'string'
    field :login, type: 'string'
    field :user_id, type: 'integer'
    field :remote_ip, type: 'string'
    field :mac_addr, type: 'string'
    field :proc_exec_name, type: 'string'
  end
  
  def self.make_voice_log_query(conds)
    
    terms = {}
    v_index = VoiceLogsIndex::VoiceLog
    
    st = conds[:start_time_bet].map { |s| s.strftime("%Y-%m-%d %H:%M:%S") }
    v_index = v_index.filter(range: {start_time: { gte: st.first, lte: st.last, boost: 2 }})
    
    if conds[:caller_no_like].present?
      v_index = v_index.filter{ ani == conds[:caller_no_like] }
    end
    
    if conds[:dialed_no_like].present?
      v_index = v_index.filter{ dnis == conds[:dialed_no_like] }
    end
    
    if conds[:extension_no_in].present?
      v_index = v_index.filter{ extension == conds[:extension_no_in] }
    end
    
    if conds[:call_direction_eq].present?
      v_index = v_index.filter{ call_direction == conds[:call_direction_eq] }
    end
    
    if conds[:call_id_eq].present?
      v_index = v_index.filter{ call_id == conds[:call_id_eq] }
    end
    
    if conds[:site_id_eq].present?
      v_index = v_index.filter{ site_id == conds[:site_id_eq] }
    end
    
    if conds[:duration_gteq].present?
      v_index = v_index.filter{ duration >= conds[:duration_gteq] }
    end
    
    if conds[:duration_lteq].present?
      v_index = v_index.filter{ duration <= conds[:duration_lteq] }
    end
    
    if conds[:call_type_in].present?
      conds[:call_type_in].each do |cate|
        v_index = v_index.filter{ call_categories == cate }
      end
    end
    
    if conds[:agent_in].present?
      aids = conds[:agent_in]
      v_index = v_index.filter{ agent_id == aids }
    end
    
    #if conds[:speaker].present?
    #  speaker_code = conds[:speaker].to_s.downcase
    #  case speaker_code
    #  when "left", "agent"
    #    v_index = v_index.filter{ recognition_results.channel == 0 }
    #  when "right", "customer"
    #    v_index = v_index.filter{ recognition_results.channel == 1 }
    #  end
    #end
    
    if conds[:reasons_in].present?
      causes = conds[:reasons_in]
      v_index = v_index.filter{ reasons.cause == causes }
    end
    
    if conds[:text].present?
      min_score = conds[:textscore] || 0.015
      v_index = v_index.query(query_string: { default_field: "recognition_results.result", query: conds[:text] })
      v_index = v_index.min_score(min_score)
      Rails.logger.info "ES Relevance min score: #{min_score}"
    end
    
    return v_index
  
  end
  
end