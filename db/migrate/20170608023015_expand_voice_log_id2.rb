class ExpandVoiceLogId2 < ActiveRecord::Migration
  def change
    change_column :wf_tasks, :voice_log_id, :integer, limit: 8, foreign_key: false
  end
end
