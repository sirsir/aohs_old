class AddTaskGroupingId < ActiveRecord::Migration
  def change
    add_column :voice_log_attributes, :grouping_id, :integer, limit: 8, foreign_key: false
    add_column :evaluation_assigned_tasks, :record_count, :integer, null: false, default: 0
    add_column :evaluation_assigned_tasks, :total_duration, :integer, null: false, default: 0
    add_column :evaluation_assigned_tasks, :unassigned_by, :integer
  end
end
