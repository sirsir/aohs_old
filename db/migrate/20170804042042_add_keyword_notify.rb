class AddKeywordNotify < ActiveRecord::Migration
  def change
    add_column :keywords, :notify_flag, :string, limit: 3
    add_column :keywords, :notify_details, :text
  end
end
