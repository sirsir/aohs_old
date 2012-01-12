class AddGroupAndPermissionToUsers < ActiveRecord::Migration
   def self.up
      add_column :users, :display_name,  :string
      add_column :users, :type,          :string
      add_column :users, :group_id,      :integer, :default => 0
      add_column :users, :permission_id, :integer, :null=>false, :default=>0
      add_column :users, :lock_version,  :integer
   end

   def self.down
      remove_column :users, :display_name
      remove_column :users, :type
      remove_column :users, :group_id
      remove_column :users, :permission_id
      remove_column :users, :lock_version
   end
end
