class CreateCallCustomers < ActiveRecord::Migration
  def change
    create_table :call_customers do |t|
      t.integer     :voice_log_id,      null: false, foreign_key: false
      t.integer     :customer_id,       null: false, foreign_key: false
      t.datetime    :updated_at
    end
    add_index :call_customers, :voice_log_id, name: 'index_vl'
  end
end