class AddUserIdCard < ActiveRecord::Migration
  def self.up
    add_column  :users, :id_card, :string, :limit => 50
  end

  def self.down
    remove_column  :users, :id_card 
  end
end
