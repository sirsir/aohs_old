class AddPrivilegeType < ActiveRecord::Migration
  
  def self.up
    add_column :privileges, :application, :string,  :limit => 50
  end

  def self.down
    remove_column :privileges, :application
  end
  
end
