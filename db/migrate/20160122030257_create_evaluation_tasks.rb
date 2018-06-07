class CreateEvaluationTasks < ActiveRecord::Migration
  def change
    create_table :evaluation_tasks do |t|
      t.string        :title,         limit: 100
      t.string        :description,   limit: 300
      t.date          :start_date
      t.date          :end_date
      t.timestamps    null: false
    end
  end
end
