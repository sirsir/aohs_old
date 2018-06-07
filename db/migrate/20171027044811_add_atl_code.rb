class AddAtlCode < ActiveRecord::Migration
  def change
    add_column :users, :atl_code, :string, limit: 15, default: ""
    add_index  :users, :atl_code
  end
end
