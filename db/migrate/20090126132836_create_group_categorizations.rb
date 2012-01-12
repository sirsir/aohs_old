class CreateGroupCategorizations < ActiveRecord::Migration
  def self.up
    create_table :group_categorizations do |t|
      t.integer :group_id,          :null=>false, :default=>0
      t.integer :group_category_id, :null=>false, :default=>0

      t.timestamps
    end
  end

  def self.down
    drop_table :group_categorizations
  end
end
