class AddCallCateBg < ActiveRecord::Migration
  def change
    add_column :call_categories, :fg_color, :string, limit: 15
    add_column :call_categories, :bg_color, :string, limit: 15
  end
end
