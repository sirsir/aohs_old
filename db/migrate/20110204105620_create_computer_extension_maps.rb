class CreateComputerExtensionMaps < ActiveRecord::Migration
  def self.up
    create_table :computer_extension_maps do |t|
      t.column      :extension_id,  :integer
      t.column      :computer_name, :string,  :limit => 100
      t.column      :ip_address,    :string,  :limit => 15
      t.timestamps
    end
  end

  def self.down
    drop_table :computer_extension_maps
  end
end
