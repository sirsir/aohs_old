class ChangeCarColumn < ActiveRecord::Migration
  def self.up
    change_column :car_numbers, :car_no, :string, :limit => 15
  end

  def self.down
    change_column :car_numbers, :car_no, :string, :limit => 10
  end
end
