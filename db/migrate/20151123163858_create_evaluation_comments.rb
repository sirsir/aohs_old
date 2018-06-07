class CreateEvaluationComments < ActiveRecord::Migration
  def change
    create_table :evaluation_comments do |t|
      t.integer       :evaluation_log_id,           null: false, foreign_key: false
      t.string        :comment_type,                null: false, limit: 1
      t.string        :comment,                     null: false, limit: 300
    end
    add_index :evaluation_comments, :evaluation_log_id, name: 'index_evl'
  end
end