class CreateCallBookmarks < ActiveRecord::Migration
  def self.up
    create_table :call_bookmarks do |t|
      t.integer :voice_log_id
      t.integer :start_msec
      t.integer :end_msec
      t.string :title
      t.string :body

      t.timestamps
    end
  end

  def self.down
    drop_table :call_bookmarks
  end
end
