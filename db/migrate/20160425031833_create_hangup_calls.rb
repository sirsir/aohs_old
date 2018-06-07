class CreateHangupCalls < ActiveRecord::Migration
  def change
    create_table :hangup_calls do |t|
      t.integer   :voice_log_id,    null: false, limit: 8, foreign_key: false
      t.string    :call_id,         null: false, limit: 30, foreign_key: false
      t.datetime  :start_time,      null: false
      t.datetime  :created_at
    end
    add_index :hangup_calls, :voice_log_id
    add_index :hangup_calls, :call_id
  end
end