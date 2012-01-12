class AddCreatAndUpdateBy < ActiveRecord::Migration
  def self.up
     add_column :keywords, :create_by,  :string
     add_column :keywords, :update_by,  :string
  end

  def self.down
     remove_column :keywords, :create_by
     remove_column :keywords, :update_by
  end
end
