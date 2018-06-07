class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string        :name,        null: false, limit: 200
      t.string        :psn_id,      foreign_key: false
      t.timestamps    null: false
    end
  end
end
