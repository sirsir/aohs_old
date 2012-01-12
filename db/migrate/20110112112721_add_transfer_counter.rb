class AddTransferCounter < ActiveRecord::Migration
  def self.up
	   add_column :voice_log_counters, :transfer_call_count, :integer, :default => 0,:limit => 1
	   add_column :voice_log_counters, :transfer_in_count, :integer, :default => 0, :limit => 1
	   add_column :voice_log_counters, :transfer_out_count, :integer, :default => 0, :limit => 1
     add_column :voice_log_counters, :transfer_duration, :integer, :default => 0
	   add_column :voice_log_counters, :transfer_ng_count, :integer, :default => 0, :limit => 2
	   add_column :voice_log_counters, :transfer_must_count, :integer, :default => 0, :limit => 2
  end

  def self.down
	   remove_column :voice_log_counters, :transfer_call_count
	   remove_column :voice_log_counters, :transfer_in_count
	   remove_column :voice_log_counters, :transfer_out_count
     remove_column :voice_log_counters, :transfer_duration
	   remove_column :voice_log_counters, :transfer_ng_count
	   remove_column :voice_log_counters, :transfer_must_count	   
  end

end
