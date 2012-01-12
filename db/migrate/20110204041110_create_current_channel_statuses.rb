class CreateCurrentChannelStatuses < ActiveRecord::Migration
  def self.up
    create_table :current_channel_statuses do |t|
      t.integer :system_id
      t.integer :device_id
      t.integer :channel_id
      t.string  :ani, :limit => 30
      t.string  :dnis, :limit => 30
      t.string  :extension, :limit => 15
      t.integer :duration
      t.datetime	:start_time
      t.integer :hangup_cause
      t.integer :call_reference
      t.integer :agent_id, :default => 0
      t.string  :voice_file_url, :limit => 300
      t.string  :call_direction, :limit => 1, :default => 'u'
      t.string  :call_id, :limit => 20
      t.integer :site_id
      t.string  :digest
      t.string  :connected, :limit => 15
    end
	
	rename_table :current_channel_statuses, :current_channel_status
	
	execute "ALTER TABLE current_channel_status MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
	
  end

  def self.down
    drop_table :current_channel_status
  end
end
