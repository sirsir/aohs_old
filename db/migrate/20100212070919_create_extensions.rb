class CreateExtensions < ActiveRecord::Migration
  def self.up
    create_table :extensions do |t|
      t.column :number,:string,:limit => 20
      t.timestamps
    end
  end

  def self.down
    drop_table :extensions
  end
end
