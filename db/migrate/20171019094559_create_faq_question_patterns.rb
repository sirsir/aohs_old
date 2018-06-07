class CreateFaqQuestionPatterns < ActiveRecord::Migration
  def change
    create_table :faq_question_patterns do |t|
      t.integer       :faq_question_id,    null: false, foreign_key: false
      t.text	      :pattern
      t.integer       :revision,	   null: false, default: 0
      t.string        :flag,               null: false, default: ""
      t.timestamps    null: false
    end
  end
end
