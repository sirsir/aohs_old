class ChangeCommentLength < ActiveRecord::Migration
  def change
    change_column :evaluation_comments, :comment, :string, limit: 1500
  end
end
