class AddCustomerFields < ActiveRecord::Migration
  def change
    add_column    :customers, :sex, :string,  limit: 1
    change_column :customers, :name, :string, limit: 200
    change_column :customers, :psn_id, :string, limit: 50, foreign_key: false
  end
end
