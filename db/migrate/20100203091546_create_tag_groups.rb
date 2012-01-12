class CreateTagGroups < ActiveRecord::Migration
  def self.up
    create_table :tag_groups do |t|
      t.column    :name, :string
      t.column    :description, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :tag_groups
  end
end
