class AddComputerInfoIndex < ActiveRecord::Migration
  def change
    add_index  :computer_infos, :ip_address, name: "index_ip"
    add_index  :computer_infos, :computer_name, name: "index_compname"
  end
end
