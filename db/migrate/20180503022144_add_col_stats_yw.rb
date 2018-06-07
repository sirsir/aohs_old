class AddColStatsYw < ActiveRecord::Migration
  def change
    add_column :statistic_calendars, :stats_yearweek, :integer
  end
end
