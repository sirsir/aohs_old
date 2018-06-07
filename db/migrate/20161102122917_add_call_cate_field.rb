class AddCallCateField < ActiveRecord::Migration
  def change
    add_column  :call_categories, :category_type, :string,  limit: 100
  end
end
