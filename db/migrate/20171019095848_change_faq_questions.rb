class ChangeFaqQuestions < ActiveRecord::Migration
  def change
     add_column :faq_questions, :enable, :boolean, default: true
     remove_column :faq_questions, :content, :text
  end
end
