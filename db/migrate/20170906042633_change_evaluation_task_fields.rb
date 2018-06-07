class ChangeEvaluationTaskFields < ActiveRecord::Migration
  def change
    add_column :evaluation_tasks, :flag,  :string, limit: 3, null: false, default: ""
    
    change_column :evaluation_task_attrs, :attr_type, :string, limit: 80
    change_column :evaluation_task_attrs, :attr_val, :string, limit: 300
    
    drop_table :evaluation_members
  end
end
