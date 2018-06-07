class CreateEvaluationAssignedTasks < ActiveRecord::Migration
  def change
    create_table :evaluation_assigned_tasks do |t|
      t.integer   :user_id,     null: false, foreign_key: false
      t.integer   :evaluation_task_id,  foreign_key: false
      t.integer   :voice_log_id,  limit: 8, foreign_key: false
      t.integer   :assigned_by
      t.datetime  :assigned_at
      t.datetime  :expiry_at
      t.datetime  :updated_at
      t.string    :flag,  null: false, default: ""
    end
  end
end
