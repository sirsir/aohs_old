class CreateGroupCategories < ActiveRecord::Migration
   def self.up
      create_table :group_categories do |t|
         t.integer :group_category_type_id, :null => false, :default => 0
         t.string  :value
         t.string  :description
         t.timestamps
      end
   end

   def self.down
      drop_table :group_categories
   end
end
