class CreateStatisticsTypes < ActiveRecord::Migration
  def self.up
    create_table :statistics_types do |t|
      t.string  :target_model
      t.string  :value_type
      t.boolean :by_agent

      t.timestamps
    end
  end

  def self.down
    drop_table :statistics_types
  end
end
