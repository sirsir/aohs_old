class CreateCallReasons < ActiveRecord::Migration
  def change
    create_table :call_reasons do |t|
      t.integer     :voice_log_id,    null: false,  limit: 8, foreign_key:  false
      t.integer     :reason_id,       foreign_key: false
      t.string      :title
    end
    add_index :call_reasons, :voice_log_id, name: 'index_vl'
  end
end
