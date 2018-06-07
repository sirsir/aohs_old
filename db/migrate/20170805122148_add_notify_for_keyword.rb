class AddNotifyForKeyword < ActiveRecord::Migration
  def change
    add_column :keyword_types, :notify_flag, :string, limit: 3
    add_column :keyword_types, :notify_details, :text
  end
end
