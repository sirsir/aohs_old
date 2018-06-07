class CustomFieldTask < ActiveRecord::Migration
  def change
    add_column :wf_tasks, :assignee_id, :integer, foreign_key: false
    add_column :wf_tasks, :flag, :string, limit: 3
    add_column :wf_task_transitions, :prev_state_id, :integer, foreign_key: false
    add_column :wf_task_transitions, :flag, :string, limit: 3
  end
end
