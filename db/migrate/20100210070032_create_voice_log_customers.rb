class CreateVoiceLogCustomers < ActiveRecord::Migration
  def self.up
    create_table :voice_log_customers do |t|
      t.column  :voice_log_id,  :integer
      t.column  :customer_id,   :integer
    end
    add_index :voice_log_customers, [:voice_log_id,:customer_id], :name => 'index1'
  end

  def self.down
    drop_table :voice_log_customers
  end
end
