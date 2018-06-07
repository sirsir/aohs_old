class ExpandCodeName < ActiveRecord::Migration
  def change
    change_column :call_categories, :code_name, :string, limit: 100
    change_column :call_categories, :title, :string, limit: 100
  end
end
