class CreateWfTasks < ActiveRecord::Migration
  def change
    create_table :wf_tasks do |t|
      t.integer     :voice_log_id,      foreign_key: false
      t.integer     :evaluation_log_id, foreign_key: false
      t.integer     :last_state_id,     foreign_key: false
      t.datetime    :content_time
      t.timestamps  null: false
    end
  end
end
