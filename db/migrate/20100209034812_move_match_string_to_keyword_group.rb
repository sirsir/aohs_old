class MoveMatchStringToKeywordGroup < ActiveRecord::Migration
  def self.up
    remove_column :keywords,:match_string
    remove_column :keywords,:create_by
    remove_column :keywords,:update_by
    add_column :keywords,:deleted,:boolean,:default=> false
    add_column :keywords,:created_by,:integer
    add_column :keywords,:updated_by,:integer
  end

  def self.down
    add_column :keywords,:match_string,:text
    add_column :keywords,:create_by,:string
    add_column :keywords,:update_by,:string
    remove_column :keywords,:deleted
    remove_column :keywords,:created_by
    remove_column :keywords,:updated_by
  end
end
