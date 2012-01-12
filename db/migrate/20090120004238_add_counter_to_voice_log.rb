class AddCounterToVoiceLog < ActiveRecord::Migration
   def self.up
      add_column :voice_logs, :keyword_count,  :integer, :null=>false, :default=>0
      add_column :voice_logs, :ngword_count,   :integer, :null=>false, :default=>0
      add_column :voice_logs, :mustword_count, :integer, :null=>false, :default=>0
      add_column :voice_logs, :bookmark_count, :integer, :null=>false, :default=>0
   end

   def self.down
      remove_column :voice_logs, :keyword_count
      remove_column :voice_logs, :ngword_count
      remove_column :voice_logs, :mustword_count
      remove_column :voice_logs, :bookmark_count
   end
end
