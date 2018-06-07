class CreateSpeechTaskLogs < ActiveRecord::Migration
  def change
    create_table :speech_task_logs, id: false do |t|
      t.integer   :id,                limit: 8, primary_key: true
      t.string    :call_id,           limit: 30, foreign_key: false
      t.integer   :voice_log_id,      limit: 8, foreign_key: false
      
      t.string    :voice_file_url,    limit: 200
      t.datetime  :task_created_at
      t.string    :recognize_mode,    limit: 15
      t.integer   :channel
      t.string    :speaker_type,      limit: 3
      t.string    :speechserver_version, limit: 15
      t.datetime  :start_task_at
      t.datetime  :start_recognize_at 
      t.string    :dsr_session_id,    limit: 10, foreign_key: false
      t.string    :dsr_mode,          limit: 10, foreign_key: false
      t.string    :dsr_profile_id,    limit: 10, foreign_key: false
      t.float     :dsr_speed_vs_accuracy
      t.string    :dsr_grammar_file_names,  limit: 50
      t.string    :dsr_server_name,         limit: 50             
      #t.string    :dsr_segmenter_properties, limit: 600    
      t.integer   :dsr_volume      
      t.integer   :dsr_snr 

      t.float     :task_delay_time 
      t.float     :recognize_preprocess_time
      t.float     :recognize_process_time
      t.float     :recognize_postprocess_time 
      t.float     :audio_load_time 
      t.float     :duration_of_audio  
      t.float     :rt  
      t.integer   :sent_byte
      
      t.integer   :number_of_utterances
      #t.integer   :number_of_vergeins_tx 
      #t.integer   :number_of_vergeins_rx 
      #t.integer   :number_of_keywords
      #t.integer   :number_of_keywords_n  
      #t.integer   :number_of_keywords_m    
      #t.integer   :number_of_long_silence
      #t.integer   :number_of_long_silence_tx 
      #t.integer   :number_of_long_silence_rx 

      t.float     :duration_of_speaking_tx
      t.float     :duration_of_speaking_rx 
      t.float     :duration_of_overwrap   
      t.float     :duration_of_silence  

      t.integer   :error
      t.datetime  :last_error_at
      t.string    :last_error_message,  limit: 200
    end
    
    execute "ALTER TABLE speech_task_logs modify COLUMN id int(8) AUTO_INCREMENT, ADD PRIMARY KEY(id)"
  
  end
end
