class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string    :name,          null: false
      t.integer   :priority_no,   null: false, default: 0
      t.string    :flag,          null: false, default: "", limit: 1
      t.string    :level,         null: false, default: "", limit: 5
      t.timestamps
    end
    add_index :roles, :name,      unique: true
    add_index :roles, [:level, :name]
    add_index :roles, :flag
  end
end
