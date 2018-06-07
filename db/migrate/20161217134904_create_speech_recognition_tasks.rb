class CreateSpeechRecognitionTasks < ActiveRecord::Migration
  def change
    create_table :speech_recognition_tasks do |t|
      t.integer     :voice_log_id,    null: false, default: 0, limit: 8, foreign_key: false
      t.string      :call_id,         limit: 50, foreign_key: false
      t.datetime    :start_time
      t.integer     :channel_no
      t.datetime    :created_at
    end
    add_index :speech_recognition_tasks, :voice_log_id
  end
end
