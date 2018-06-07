class CreateVoiceLogCounters < ActiveRecord::Migration
  def change
    create_table :voice_log_counters do |t|
      t.integer       :voice_log_id,    null:false,  foreign_key: false, limit: 8
      t.integer       :counter_type,    null:false
      t.integer       :valu,            default: 0
      t.datetime      :updated_at
    end
    add_index :voice_log_counters, :voice_log_id, name: 'index_vl'
  end
end
