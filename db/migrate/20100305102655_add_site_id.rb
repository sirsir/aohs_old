class AddSiteId < ActiveRecord::Migration
  def self.up
    add_column  :voice_logs, :site_id,  :integer
  end

  def self.down
    remove_column  :voice_logs, :site_id,  :integer
  end
end
