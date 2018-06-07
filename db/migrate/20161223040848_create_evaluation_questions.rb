class CreateEvaluationQuestions < ActiveRecord::Migration
  def change
    create_table :evaluation_questions do |t|
      t.string        :title,               limit: 150
      t.integer       :order_no
      t.integer       :question_group_id,   foreign_key: false
      t.string        :flag,                limit: 1
      t.timestamps                          null: false
    end
  end
end
