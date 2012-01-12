class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :name
      t.string :target
      t.string :status
      t.datetime :start_time
      t.datetime :complete_time
      t.integer :sevelity
    end
  end

  def self.down
    drop_table :events
  end
end
