class CreatePrivileges < ActiveRecord::Migration
  def change
    create_table :privileges do |t|
      t.string     :category,       null: false, default: "", limit: 100
      t.string     :module_name,    null: false, limit: 100
      t.string     :event_name,     null: false, limit: 100
      t.string     :section,        null: false, limir: 100
      t.string     :description,    null: false, default: "", limit: 150
      t.string     :display_name,   limit: 100
      t.string     :order_no,       null: false, default: "", limit: 20
      t.string     :flag,           null: false, default: "", limit: 2
    end
    add_index :privileges, [:module_name, :event_name], unique: true
  end
end
