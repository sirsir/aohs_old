class CreateCallInformations < ActiveRecord::Migration
  def change
    create_table :call_informations do |t|
      t.integer       :voice_log_id,    null: false, foreign_key: false, limit: 8
      t.integer       :start_msec,      default: 0
      t.integer       :end_msec,        default: 0
      t.datetime      :start_time
      t.datetime      :end_time
      t.string        :event,           limit:  40
      t.integer       :agent_id,        default: 0, foreign_key: false
      t.string        :number1,         limit: 50
      t.string        :number2,         limit: 50
      t.string        :extension,       limit: 50
      t.string        :call_id,         limit: 45, foreign_key: false
      t.string        :is_transfer,     limit: 1
    end
    add_index :call_informations, :voice_log_id, name: 'index_vl'
    add_index :call_informations, :start_time, name: 'index_vl_stime'
  end
end
