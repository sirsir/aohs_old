class RenameIdlesAndActivitiesLog < ActiveRecord::Migration
  def self.up
    rename_table :user_idles, :user_idle_logs
    rename_table :user_activities, :user_activity_logs
  end

  def self.down
    rename_table :user_idle_logs, :user_idles
    rename_table :user_activity_logs, :user_activities
  end
  
end
