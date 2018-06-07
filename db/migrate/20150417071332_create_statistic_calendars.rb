class CreateStatisticCalendars < ActiveRecord::Migration
  def change
    create_table :statistic_calendars do |t|
      t.date          :stats_date,        null: false
      t.integer       :stats_year,        null: false
      t.integer       :stats_yearmonth,   null: false
      t.integer       :stats_week,        null: false 
      t.integer       :stats_day,         null: false
      t.integer       :stats_hour,        null: false
    end
    add_index :statistic_calendars, [:stats_date, :stats_hour], name: 'index_datehr', unique: true
  end
end