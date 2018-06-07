class CreateUserExtensionLogs < ActiveRecord::Migration
  def change
    create_table :user_extension_logs do |t|
      t.datetime     :log_date,   null: false
      t.string       :extension,  limit: 15
      t.string       :did,        limit: 20
      t.integer      :agent_id,   foreign_key: false
    end
    add_index :user_extension_logs, :log_date
    add_index :user_extension_logs, :agent_id
  end
end
