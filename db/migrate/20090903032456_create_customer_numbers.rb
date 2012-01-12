class CreateCustomerNumbers < ActiveRecord::Migration
  def self.up
    create_table :customer_numbers do |t|
      t.integer   :customer_id
      t.string    :number
      t.timestamps
    end
  end

  def self.down
    drop_table :customer_numbers
  end
end
