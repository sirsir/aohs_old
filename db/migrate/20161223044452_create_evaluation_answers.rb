class CreateEvaluationAnswers < ActiveRecord::Migration
  def change
    create_table :evaluation_answers do |t|
      t.integer       :evaluation_question_id,  foreign_key: false
      t.string        :answer_type,             limit: 50
      t.text          :answer_list
      t.float         :max_score
      t.string        :flag,                    limit: 1
      t.integer       :revision_no
      t.string        :ana_settings
      t.timestamps    null: false
    end
  end
end
