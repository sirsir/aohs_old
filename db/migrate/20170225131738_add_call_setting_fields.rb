class AddCallSettingFields < ActiveRecord::Migration
  def change
    add_column :evaluation_plans, :call_settings, :text
    add_column :evaluation_plans, :asst_flag, :string, limit: 3
  end
end
