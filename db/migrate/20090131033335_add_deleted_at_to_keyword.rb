class AddDeletedAtToKeyword < ActiveRecord::Migration
   def self.up
      add_column :keywords, :deleted_at, :datetime
   end

   def self.down
      remove_column :keywords, :deleted_at
   end
end
