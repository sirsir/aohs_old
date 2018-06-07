class CreateFaqTags < ActiveRecord::Migration
  def change
    create_table :faq_tags do |t|
      t.integer   :faq_question_id,   null: false, foreign_key: false
      t.string    :tag_name
      t.string    :tag_type
      t.timestamps null: false
    end
    add_index :faq_tags, :faq_question_id
    add_index :faq_tags, :tag_name
  end
end
