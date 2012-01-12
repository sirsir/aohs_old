class AddExpiredDateUser < ActiveRecord::Migration
  def self.up
    add_column :users, :expired_date,  :datetime
  end

  def self.down
    remove_column :users,:expired_date
  end
  
end
