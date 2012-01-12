class CreateWatcherLogs < ActiveRecord::Migration
  def self.up
    create_table :watcher_logs do |t|
      t.column  :check_time,  :datetime
      t.column  :agent_id,    :string,    :length => 50
      t.column  :extension,   :string,    :length => 20
      t.column  :extension2,  :string,    :length => 20
      t.column  :login_name,  :string,    :length => 50
      t.column  :remote_ip,   :string,    :length => 50
    end
  end

  def self.down
    drop_table :watcher_logs
  end
end
