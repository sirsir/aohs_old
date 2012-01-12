class ChangeDisposition < ActiveRecord::Migration
  def self.up
    rename_column :voice_logs, :disposition, :voice_file_url
  end

  def self.down
    rename_column :voice_logs, :voice_file_url, :disposition 
  end
end
