class AddAtlFields < ActiveRecord::Migration
  def change
    add_column :user_atl_attrs, :grade, :string,  limit: 5
    add_column :user_atl_attrs, :section_id, :string, limit: 15, foreign_key: false
    #add_column :user_atl_attrs, :section_name, :string, limit: 30
    add_column :user_atl_attrs, :dummy_flag, :string, limit: 1
  end
end
