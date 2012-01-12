class AddCustomerFlag < ActiveRecord::Migration
  def self.up
    add_column  :customers, :flag,  :string, :length => 1
  end

  def self.down
    remove_column :customers, :flag
  end
end
