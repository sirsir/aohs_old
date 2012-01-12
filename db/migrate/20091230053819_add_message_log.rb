class AddMessageLog < ActiveRecord::Migration
  def self.up
    add_column :logs, :message,  :string
  end

  def self.down
    remove_column :logs, :message
  end
end
