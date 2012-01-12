class CreateCarNumbers < ActiveRecord::Migration
  def self.up
    create_table :car_numbers do |t| 
      t.column      :customer_id, :integer
      t.column      :car_no,      :string,  :limit => 10
      t.column      :flag,        :string,  :limit => 1
      t.timestamps
    end
	add_index :car_numbers, :customer_id, :name => 'cust_index1'
	 
  end

  def self.down
    drop_table :car_numbers
  end
end
