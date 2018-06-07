class AddPriorityKey < ActiveRecord::Migration
  def change
    add_column :evaluation_plans, :order_no, :integer
    add_column :call_categories, :order_no, :integer
  end
end
