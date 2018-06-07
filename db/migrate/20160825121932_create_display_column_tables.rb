class CreateDisplayColumnTables < ActiveRecord::Migration
  def change
    create_table :display_column_tables do |t|
      t.string      :table_name,      null: false, limit: 50
      t.string      :column_name,     null: false, limit: 50
      t.string      :variable_name,   null: false, limit: 100
      t.string      :sortable,        null: false, default: "", limit: 1
      t.integer     :order_no,        null: false, default: 0
      t.string      :flag,            null: false, default: "", limit: 1
      t.timestamps null: false
    end
    add_index :display_column_tables, :table_name, name: 'index_tbln'
  end
end