class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string    :name,          null: false, limit: 100
      t.string    :short_name,    null: false, limit: 100
      t.string    :description,   limit: 100
      t.integer   :level_no,      null: false, default: 0,  limit: 4
      t.integer   :parent_id,     null: false, default: 0,  foreign_key: false
      t.string    :seq_no,        null: false, default: "", limit: 45
      t.string    :pathname,      null: false, default: ""
      t.string    :flag,          null: false, default: "", limit: 1
      t.timestamps
    end
    add_index :groups, :name
    add_index :groups, :short_name
    add_index :groups, :parent_id
    add_index :groups, :seq_no
  end
end
