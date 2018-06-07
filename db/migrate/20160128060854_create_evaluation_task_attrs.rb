class CreateEvaluationTaskAttrs < ActiveRecord::Migration
  def change
    create_table :evaluation_task_attrs do |t|
      t.integer         :evaluation_task_id,    null: false,  foreign_key: false
      t.string          :attr_type,             null: false,  limit: 15
      t.integer         :attr_id,               foreign_key: false
      t.string          :attr_val,              limit: 150
      t.timestamps      null: false
    end
    add_index :evaluation_task_attrs, :evaluation_task_id, name: 'index_etask'
  end
end
