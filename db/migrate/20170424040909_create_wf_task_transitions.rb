class CreateWfTaskTransitions < ActiveRecord::Migration
  def change
    create_table :wf_task_transitions do |t|
      t.integer     :wf_task_id,        foreign_key: false
      t.integer     :wf_task_state_id,  foreign_key: false
      t.integer     :assignee_id,       foreign_key: false
      t.timestamps  null: false
    end
  end
end
