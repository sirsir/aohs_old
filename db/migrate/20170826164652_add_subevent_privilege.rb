class AddSubeventPrivilege < ActiveRecord::Migration
  def change
    add_column :privileges, :link_name, :string
    remove_index :privileges, [:module_name, :event_name]
    add_index :privileges, [:module_name, :event_name]
  end
end
