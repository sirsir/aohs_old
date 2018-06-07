class CreateCallTranscriptions < ActiveRecord::Migration
  def change
    create_table :call_transcriptions do |t|
      t.integer         :voice_log_id,    null: false, foreign_key: false
      t.integer         :speaker_id,      foreign_key: false
      t.string          :speaker_type,    null: false
      t.integer         :channel,         null: false, default: 0
      t.integer         :start_msec
      t.integer         :end_msec
      t.string          :result,          null: false, limit: 300
    end
    add_index :call_transcriptions, :voice_log_id, name: 'index_vl'
  end
end