class CreateEvaluationCalls < ActiveRecord::Migration
  def change
    create_table :evaluation_calls do |t|
      t.integer   :evaluation_plan_id,        null: false,  foreign_key: false
      t.integer   :evaluation_log_id,         null: false,  foreign_key: false
      t.integer   :voice_log_id,              null: false,  foreign_key: false
      t.date      :call_date
      t.time      :call_time
      t.string    :ani,                       limit: 25
      t.string    :dnis,                      limit: 25
      t.integer   :duration,                  default: 0
      t.string    :flag,                      null: false,  default: ''
    end
    add_index :evaluation_calls, :evaluation_plan_id, name: 'index_evplan'
    add_index :evaluation_calls, :evaluation_log_id, name: 'index_evl'
    add_index :evaluation_calls, :voice_log_id, name: 'index_vl'
  end
end