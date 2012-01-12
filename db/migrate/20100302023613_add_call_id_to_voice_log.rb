class AddCallIdToVoiceLog < ActiveRecord::Migration
  def self.up
    add_column :voice_logs, :call_id, :string
    add_index  :voice_logs, :call_id
  end

  def self.down
    remove_index :voice_logs, :call_id
    remove_column :voice_logs, :call_id
  end
end
