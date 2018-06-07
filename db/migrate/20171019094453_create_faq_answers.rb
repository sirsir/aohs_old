class CreateFaqAnswers < ActiveRecord::Migration
  def change
    create_table :faq_answers do |t|
      t.integer      :faq_question_id,  null: false, foreign_key: false
      t.text         :content
      t.text         :conditions
      t.integer      :revision,         null: false, default: 0
      t.string       :flag,             limit: 5, null: false, default: ""
      t.timestamps   null: false
    end
  end
end
