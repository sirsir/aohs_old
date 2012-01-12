class AddLogType < ActiveRecord::Migration
  def self.up
    add_column :logs, :application, :string,  :limit => 50
  end

  def self.down
    remove_column :logs, :application
  end
end
