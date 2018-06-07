class CreateWfTaskStates < ActiveRecord::Migration
  def change
    create_table :wf_task_states do |t|
      t.string      :name
      t.timestamps  null: false
    end
  end
end
