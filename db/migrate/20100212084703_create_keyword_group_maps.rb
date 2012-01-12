class CreateKeywordGroupMaps < ActiveRecord::Migration
  def self.up
    create_table :keyword_group_maps do |t|
      t.column :keyword_id,:integer,:null => false
      t.column :keyword_group_id,:integer,:null => false
      t.timestamps
    end
    add_index :keyword_group_maps, [:keyword_id,:keyword_group_id], :name => 'index1'
  end

  def self.down
    drop_table :keyword_group_maps  
  end
end
