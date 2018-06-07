class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string      :name,          null: false,  limit: 100
      t.integer     :parent_id,     null: false,  default: 0,  foreign_key: false
      t.string      :color_code,    limit: 15
      t.timestamps
    end
  end
end
