class RemoveVlCreatedAndUpdatedAt < ActiveRecord::Migration
  def self.up
    remove_column :voice_logs, :created_at
    remove_column :voice_logs, :updated_at
  end

  def self.down
  end
end
