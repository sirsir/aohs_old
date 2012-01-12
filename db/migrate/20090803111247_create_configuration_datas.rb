class CreateConfigurationDatas < ActiveRecord::Migration
  def self.up
    create_table :configuration_datas do |t|
      t.integer     :configuration_id
      t.integer     :config_type
      t.integer     :config_type_id
      t.string      :value
      t.timestamps
    end
    add_index :configuration_datas, [:configuration_id,:config_type], :name => 'index1'
  end

  def self.down
    drop_table :configuration_datas
  end
end
