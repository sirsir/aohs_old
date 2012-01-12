class AddTransferFields < ActiveRecord::Migration
  def self.up
	add_column :voice_logs, :ext_transfer, :string, :length => 5
	add_column :voice_logs, :answer_time, :string, :length => 45 
  end
 
  def self.down
  end
end
