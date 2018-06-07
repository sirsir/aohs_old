class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.string        :name,            null: false,  limit: 100
      t.string        :keyword_type,    null: false,  limit: 3
      t.string        :flag,            null: false,  default: "", limit: 1
      t.integer       :parent_id,       null: false,  default: 0, foreign_key: false
      t.timestamps    null: false
    end
    add_index :keywords, :keyword_type
    add_index :keywords, :parent_id
  end
end
