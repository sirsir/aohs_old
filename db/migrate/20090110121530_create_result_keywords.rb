class CreateResultKeywords < ActiveRecord::Migration
   def self.up
      create_table :result_keywords do |t|
         t.integer :start_msec
         t.integer :end_msec
         t.integer :voice_log_id, :null=>false, :default=>0
         t.integer :keyword_id, :null=>false, :default=>0    
         t.timestamps
      end
   end

   def self.down
      drop_table :result_keywords
   end
end
