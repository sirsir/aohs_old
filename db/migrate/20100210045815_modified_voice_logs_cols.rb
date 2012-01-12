class ModifiedVoiceLogsCols < ActiveRecord::Migration
  def self.up

    remove_index :voice_logs, :name => 'vc_index1'

    remove_column :voice_logs, :agent_name
    remove_column :voice_logs, :group_id
    remove_column :voice_logs, :group_name
    remove_column :voice_logs, :start_date
    remove_column :voice_logs, :start_time
    remove_column :voice_logs, :customer_id

    add_column :voice_logs, :start_time, :datetime
    add_index :voice_logs, [:start_time,:agent_id], :name => 'vc_index1'
    add_index :voice_logs, :start_time
  end

  def self.down
    
    remove_index :voice_logs, :start_time
    remove_index :voice_logs, :name => 'vc_index1'       # [:start_time,:agent_id]
    remove_column :voice_logs, :start_time, :datetime

    add_column :voice_logs, :agent_name, :string
    add_column :voice_logs, :group_id,   :integer
    add_column :voice_logs, :group_name, :string
    add_column :voice_logs, :start_date, :date
    add_column :voice_logs, :start_time, :time
    add_column :voice_logs, :customer_id, :integer

    add_index :voice_logs, [:start_date,:start_time,:agent_id], :name => 'vc_index1'
    
  end
  
end
