class CreateDids < ActiveRecord::Migration
  def self.up
    create_table :dids do |t|
      t.column :number,:string,:limit => 20
      t.column :extension_id,:integer
      t.timestamps
    end
  end

  def self.down
    drop_table :dids
  end
end
