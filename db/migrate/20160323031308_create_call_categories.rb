class CreateCallCategories < ActiveRecord::Migration
  def change
    create_table :call_categories do |t|
      t.string      :title,         limit: 25, null: false
      t.string      :code_name,     limit: 10
      t.string      :flag,          limit: 1, null: false, default: ""
      t.timestamps  null: false
    end
  end
end