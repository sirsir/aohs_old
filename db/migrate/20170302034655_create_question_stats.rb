class CreateQuestionStats < ActiveRecord::Migration
  def change
    create_table :evaluation_question_stats do |t|
      t.integer       :evaluation_question_id,  null: false, foreign_key: false
      t.date          :call_date
      t.integer       :agent_id,                null: false, foreign_key: false
      t.integer       :group_id,                null: false, foreign_key: false
      t.string        :choice_title,            null: false, default: ""
      t.integer       :record_count,            null: false, default: 0
    end
    add_index :evaluation_question_stats, [:call_date, :evaluation_question_id], name: 'index_quest_date'
  end
end
