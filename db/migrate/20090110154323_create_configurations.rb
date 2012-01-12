class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :configurations do |t|
      t.string :variable
      t.string :default_value
      t.string :description
      t.string :variable_type
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :configurations
  end
end
