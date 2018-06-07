class CreateUserPictures < ActiveRecord::Migration
  def change
    create_table :user_pictures do |t|
      t.integer     :user_id,         null: false, foreign_key: false
      t.binary      :pic_data,        null: false, :size => 1.megabyte
      t.string      :content_type,    limit: 25
      t.integer     :file_size,       default: 0
      t.string      :flag,            limit: 1, default: ''
    end
    add_index :user_pictures, :user_id
  end
end
