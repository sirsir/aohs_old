class AddDeleteFlagToUsers < ActiveRecord::Migration
  def self.up
    add_column :users,:flag,:boolean, :default => false
  end

  def self.down
    remove_column :users,:flag
  end
  
end
