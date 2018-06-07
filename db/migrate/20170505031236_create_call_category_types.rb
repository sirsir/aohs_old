class CreateCallCategoryTypes < ActiveRecord::Migration
  def change
    create_table :call_category_types do |t|
      t.string    :title,     null: false, limit: 100
      t.integer   :order_no
      t.integer   :parent_id,   foreign_key: false
    end
  end
end
