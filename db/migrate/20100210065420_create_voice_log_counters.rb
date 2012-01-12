class CreateVoiceLogCounters < ActiveRecord::Migration
  def self.up
    create_table :voice_log_counters do |t|
      t.column :voice_log_id, :integer, :limit => 8
      t.column :keyword_count, :integer, :default => 0, :limit => 2
      t.column :ngword_count, :integer, :default => 0, :limit => 2
      t.column :mustword_count, :integer, :default => 0,:limit => 2
      t.column :bookmark_count, :integer, :default => 0, :limit => 1
      t.timestamps
    end
    add_index :voice_log_counters, :voice_log_id
  end

  def self.down
    drop_table :voice_log_counters  
  end
end
