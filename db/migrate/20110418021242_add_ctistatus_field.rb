class AddCtistatusField < ActiveRecord::Migration
  def self.up
    add_column :current_watcher_status, :ctistatus, :string, :length => 10
    add_column :watcher_logs,           :ctistatus, :string, :length => 10
  end

  def self.down
    remove_column :current_watcher_status, :ctistatus
    remove_column :watcher_logs,           :ctistatus
  end
end
