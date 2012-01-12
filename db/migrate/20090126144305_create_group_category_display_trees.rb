class CreateGroupCategoryDisplayTrees < ActiveRecord::Migration
  def self.up
    create_table :group_category_display_trees do |t|
      t.string :group_category_type
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
    end
  end

  def self.down
    drop_table :group_category_display_trees
  end
end
