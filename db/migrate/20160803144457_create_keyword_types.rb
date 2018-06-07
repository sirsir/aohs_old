class CreateKeywordTypes < ActiveRecord::Migration
  def change
    create_table :keyword_types do |t|
      t.string      :name,        limit: 50
      t.string      :description, limit: 150
      t.string      :flag,        limit: 1, null: false, default: ""
      t.timestamps null: false
    end
  end
end
