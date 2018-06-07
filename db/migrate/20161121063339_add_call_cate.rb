class AddCallCate < ActiveRecord::Migration
  def change
    add_column  :call_categories, :alias_name, :string,  limit: 200
  end
end
