class CreateEvaluationQuestionGroups < ActiveRecord::Migration
  def change
    create_table :evaluation_question_groups do |t|
      t.string        :title,         limit: 150
      t.integer       :order_no,      null: false, default: 0
      t.string        :flag,          limit: 1
      t.timestamps    null: false
    end
  end
end
