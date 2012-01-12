class CreateVoiceLogs < ActiveRecord::Migration
  def self.up
    create_table :voice_logs do |t|
      t.integer :system_id
      t.integer :device_id
      t.integer :channel_id
      t.string  :ani, :limit => 30
      t.string  :dnis, :limit => 30
      t.string  :extension, :limit => 30
      t.date    :start_date
      t.time    :start_time
      t.integer :duration
      t.integer :hangup_cause
      t.integer :call_reference
      t.integer :agent_id
      t.string  :agent_name
      t.integer :group_id
      t.string  :group_name
      t.string  :disposition, :limit => 300
      t.string  :customer_id
      t.string  :call_direction, :limit => 1, :default => 'u'

      t.timestamps
    end
  end

  def self.down
    drop_table :voice_logs
  end
end
