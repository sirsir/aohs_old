class AddDomainLogin < ActiveRecord::Migration
  def change
    add_column  :computer_logs, :domain_name, :string,  limit: 100
  end
end
