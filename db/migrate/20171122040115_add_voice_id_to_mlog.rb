class AddVoiceIdToMlog < ActiveRecord::Migration
  def change
    add_column :message_logs, :voice_log_id, :integer, limit: 8, foreign_key: false
    add_column :message_logs, :item_id, :integer, foreign_key: false
    add_column :message_logs, :comment, :string
    add_index  :message_logs, :voice_log_id, name: "index_voice_id"
  end
end
