class CreateCustomerNumbers < ActiveRecord::Migration
  def self.up
    create_table :customer_numbers do |t|
      t.integer   :customer_id
      t.string    :number
      t.timestamps
    end
	add_index :customer_numbers, :customer_id, :name => 'cust_index1'
	 
  end

  def self.down
    drop_table :customer_numbers
  end
end
