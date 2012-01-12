class AddSexToUser < ActiveRecord::Migration
   def self.up
      # {u, f, m}
      add_column :users, :sex, :string, :limit=>1, :null=>false, :default=>'u'
   end

   def self.down
      remove_column :users, :sex
   end
end
