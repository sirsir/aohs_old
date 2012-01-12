class ChangeUserAttributeFromPermissionToRole < ActiveRecord::Migration
   def self.up
      remove_column :users, :permission_id
      add_column    :users, :role_id, :integer, :null=>false, :default=>0
   end

   def self.down
      remove_column :users, :role_id
      add_column    :users, :permission_id, :integer, :null=>false, :default=>0
   end
end
