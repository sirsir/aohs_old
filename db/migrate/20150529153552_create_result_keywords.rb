class CreateResultKeywords < ActiveRecord::Migration
  def change
    create_table :result_keywords do |t|
      t.integer     :start_msec,        default: 0
      t.integer     :end_msec,          default: 0
      t.integer     :keyword_id,        null: false, foreign_key: false
      t.integer     :voice_log_id,      null: false, limit: 8, foreign_key: false
      t.string      :flag,              null: false, default: "", limit: 1
      t.timestamps                      null: false
    end
    add_index :result_keywords, :voice_log_id
  end
end