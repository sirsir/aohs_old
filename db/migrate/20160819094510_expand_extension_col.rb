class ExpandExtensionCol < ActiveRecord::Migration
  def change
    change_column :voice_logs, :extension,          :string, limit: 15
    change_column :voice_logs_details, :extension,  :string, limit: 15
    change_column :voice_logs_today, :extension,    :string, limit: 15
  end
end