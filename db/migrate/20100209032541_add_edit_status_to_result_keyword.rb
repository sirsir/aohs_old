class AddEditStatusToResultKeyword < ActiveRecord::Migration
  def self.up
    add_column :result_keywords,:edit_status,:string,:limit => 1
  end

  def self.down
    remove_column :result_keywords
  end
end
