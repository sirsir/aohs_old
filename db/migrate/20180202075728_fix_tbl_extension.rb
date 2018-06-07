class FixTblExtension < ActiveRecord::Migration
  def change
    add_column :current_computer_status, :domain_name, :string, limit: 50
    remove_index :user_extension_maps, name: "index_aed"
  end
end
