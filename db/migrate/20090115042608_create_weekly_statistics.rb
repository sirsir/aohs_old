class CreateWeeklyStatistics < ActiveRecord::Migration
  def self.up
    create_table :weekly_statistics do |t|
      t.integer :cweek
      t.integer :cwyear
      t.date :start_day, :null => false
      t.integer :agent_id
      t.integer :keyword_id
      t.integer :statistics_type_id, :null => false
      t.integer :value

      t.timestamps
    end
  end

  def self.down
    drop_table :weekly_statistics
  end
end
