class AddOrderCategoryType < ActiveRecord::Migration
  def self.up
    add_column :group_category_types, :order_id, :integer
  end

  def self.down
    remove_column :group_category_types, :order_id
  end
end
