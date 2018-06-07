class ChangePicSize < ActiveRecord::Migration
  def change
    change_column :user_pictures, :pic_data, :binary, limit: 10.megabyte
  end
end
