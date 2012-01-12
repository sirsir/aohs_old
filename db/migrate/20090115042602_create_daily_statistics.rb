class CreateDailyStatistics < ActiveRecord::Migration
  def self.up
    create_table :daily_statistics do |t|
      t.date    :start_day, :null => false
      t.integer :agent_id
      t.integer :keyword_id
      t.integer :statistics_type_id, :null => false
      t.integer :value

      t.timestamps
    end
  end

  def self.down
    drop_table :daily_statistics
  end
end
