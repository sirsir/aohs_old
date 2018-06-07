class CreateMessageLogs < ActiveRecord::Migration
  def change
    create_table :message_logs do |t|
      t.string      :message_type,    limit: 50
      t.integer     :who_sent
      t.integer     :who_receive
      t.integer     :reference_id,    foreign_key: false
      t.string      :read_flag,       limit: 1
      t.string      :useful_flag,     limit: 1
      t.string      :message_uuid,    limit: 50
      t.timestamps null: false
    end
    add_index :message_logs, :message_type
    add_index :message_logs, [:message_type, :reference_id], name: 'index_type_id'
  end
end
