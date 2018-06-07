class CreateCallAnnotations < ActiveRecord::Migration
  def change
    create_table :call_annotations do |t|
      t.integer     :voice_log_id,    null: false,  limit: 8, foreign_key:  false
      t.string      :annot_type,      null: false,  limit: 3
      t.integer     :start_msec
      t.integer     :end_msec
      t.string      :title,           limit: 150
    end
    add_index :call_annotations, :voice_log_id, name: 'index_vl'
  end
end