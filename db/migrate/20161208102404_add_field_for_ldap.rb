class AddFieldForLdap < ActiveRecord::Migration
  def change
    add_column  :users, :domain_name, :string,  limit: 150
    add_column  :users, :auth_type,   :string,  limit: 10
  end
end
