class ExpandVoiceLogId < ActiveRecord::Migration
  def change
    change_column :call_customers, :voice_log_id, :integer, limit: 8, foreign_key: false
    change_column :evaluation_calls, :voice_log_id, :integer, limit: 8, foreign_key: false
    change_column :call_transcriptions, :voice_log_id, :integer, limit: 8, foreign_key: false
  end
end
