class ModifyDisplayColumnTables < ActiveRecord::Migration
  def change
    add_column :display_column_tables, :searchable, :string,  limit: 1, null: false, default: ""
    add_column :display_column_tables, :column_type, :string,  limit: 50
  end
end
