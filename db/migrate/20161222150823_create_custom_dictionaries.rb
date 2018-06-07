class CreateCustomDictionaries < ActiveRecord::Migration
  def change
    create_table :custom_dictionaries do |t|
      t.string      :word,        limit: 150
      t.string      :spoken_word, limit: 150
      t.string      :class_map,   limit: 50
      t.timestamps                null: false
    end
  end
end
