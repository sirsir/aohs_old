class AddTagCode < ActiveRecord::Migration
  def change
    add_column :tags, :tag_code, :string, limit: 20
    add_index :tags, :tag_code
  end
end
