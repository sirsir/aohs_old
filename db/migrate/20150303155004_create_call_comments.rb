class CreateCallComments < ActiveRecord::Migration
  def change
    create_table :call_comments do |t|
      t.integer     :voice_log_id,    null: false,  foreign_key: false, limit: 8
      t.integer     :start_sec
      t.integer     :end_sec
      t.text        :comment
      t.integer     :created_by
      t.string      :flag,            null: false, default: "",  limit: 1
      t.timestamps                    null: false
    end
    add_index :call_comments, :voice_log_id
  end
end
