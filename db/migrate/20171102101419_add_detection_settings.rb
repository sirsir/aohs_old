class AddDetectionSettings < ActiveRecord::Migration
  def change
    add_column :keywords, :detection_settings, :text
  end
end
