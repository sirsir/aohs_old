class CreateComputerInfos < ActiveRecord::Migration
  def change
    create_table :computer_infos do |t|
      t.string      :computer_name,   null: false, limit: 100
      t.string      :ip_address,      null: false, limit: 50
      t.integer     :extension_id,    foreign_key: false 
      t.timestamps  null: false
    end
    add_index :computer_infos,  :extension_id
    add_index :computer_infos,  :ip_address
  end
end
