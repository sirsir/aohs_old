class CreateFaqQuestions < ActiveRecord::Migration
  def change
    create_table :faq_questions do |t|
      t.string      :question,      null: false
      t.text        :content
      t.string      :flag,          limit: 3, null: false, default: ""
      t.timestamps null: false
    end
  end
end
