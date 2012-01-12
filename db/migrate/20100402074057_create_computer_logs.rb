class CreateComputerLogs < ActiveRecord::Migration
  def self.up
    create_table :computer_logs do |t|
      t.column :check_time, 	:datetime
      t.column :computer_name,  :string
      t.column :login_name,	    :string
      t.column :os_version,     :string
      t.column :java_version,   :string
      t.column :watcher_version,:string
      t.column :audioviewer_version, :string
      t.column :cti_version, :string
      t.column :versions, :string
      t.column :remote_ip,  :string,  :limit => 15
      t.timestamps
    end
  end

  def self.down
    drop_table :computer_logs
  end
end
