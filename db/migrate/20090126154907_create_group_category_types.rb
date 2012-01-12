class CreateGroupCategoryTypes < ActiveRecord::Migration
  def self.up
    create_table :group_category_types do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :group_category_types
  end
end
