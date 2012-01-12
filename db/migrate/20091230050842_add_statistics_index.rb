class AddStatisticsIndex < ActiveRecord::Migration
  def self.up
    add_index :monthly_statistics, [:start_day,:agent_id,:statistics_type_id], :name => 'monthly_index'
    add_index :weekly_statistics, [:start_day,:agent_id,:statistics_type_id], :name => 'weekly_index'
    add_index :daily_statistics, [:start_day,:agent_id,:statistics_type_id], :name => 'daily_index'
    add_index :monthly_statistics, [:start_day,:keyword_id,:statistics_type_id], :name => 'monthly_index2'
    add_index :weekly_statistics, [:start_day,:keyword_id,:statistics_type_id], :name => 'weekly_index2'
    add_index :daily_statistics, [:start_day,:keyword_id,:statistics_type_id], :name => 'daily_index2'    
  end

  def self.down
    remove_index :monthly_statistics, [:start_day,:agent_id,:statistics_type_id], :name => 'monthly_index'
    remove_index :weekly_statistics, [:start_day,:agent_id,:statistics_type_id], :name => 'weekly_index'
    remove_index :daily_statistics, [:start_day,:agent_id,:statistics_type_id], :name => 'daily_index'
    remove_index :monthly_statistics, [:start_day,:keyword_id,:statistics_type_id], :name => 'monthly_index2'
    remove_index :weekly_statistics, [:start_day,:keyword_id,:statistics_type_id], :name => 'weekly_index2'
    remove_index :daily_statistics, [:start_day,:keyword_id,:statistics_type_id], :name => 'daily_index2'     
  end
end
