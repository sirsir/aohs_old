class CreateComputerLogs < ActiveRecord::Migration
  def change
    create_table :computer_logs, :id => false do |t|
      t.datetime    :check_time
      t.string      :computer_name,       limit: 60
      t.string      :login_name,          limit: 60
      t.string      :os_version,          limit: 30
      t.string      :java_version,        limit: 30
      t.string      :watcher_version,     limit: 30
      t.string      :audioviewer_version, limit: 30
      t.string      :cti_version,         limit: 30
      t.string      :remote_ip,           limit: 50
      t.string      :computer_event,      limit: 20
      t.datetime    :created_at
    end
    add_index :computer_logs, [:remote_ip, :check_time]
    add_index :computer_logs, [:login_name, :check_time]
    add_index :computer_logs, [:check_time]
  end
end
