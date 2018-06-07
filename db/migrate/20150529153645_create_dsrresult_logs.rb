class CreateDsrresultLogs < ActiveRecord::Migration
  def change
    create_table :dsrresult_logs do |t|
      t.integer       :voice_log_id,      foreign_key: false, limit: 8
      t.integer       :agent_id,          foreign_key: false
      t.string        :server_name,       limit: 20
      t.datetime      :start_time
      t.text          :result
    end
    add_index :dsrresult_logs, [:voice_log_id]
  end
end