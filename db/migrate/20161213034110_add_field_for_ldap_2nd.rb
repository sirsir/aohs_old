class AddFieldForLdap2nd < ActiveRecord::Migration
  def change
    add_column  :roles, :ldap_dn, :string,  limit: 150
    add_column  :groups, :ldap_dn, :string,  limit: 150
  end
end
