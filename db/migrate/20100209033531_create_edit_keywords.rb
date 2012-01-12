class CreateEditKeywords < ActiveRecord::Migration
  def self.up
    create_table :edit_keywords do |t|
      t.column :keyword_id,:integer, :null => false
      t.column :voice_log_id,:integer, :null => false
      t.column :start_msec,:integer
      t.column :end_msec,:integer
      t.column :result_keyword_id,:integer
      t.column :user_id,:integer
      t.column :edit_status, :string, :limit => 1
      t.timestamps
    end
    
    add_index :edit_keywords, [:keyword_id,:voice_log_id], :name => 'indexkv'

  end

  def self.down
    drop_table :edit_keywords
  end
end
