class CreateTaggings < ActiveRecord::Migration
  def change
    create_table :taggings do |t|
      t.integer     :tag_id,        foreign_key: false 
      t.integer     :tagged_id,     foreign_key: false, limit: 8
      t.integer     :updated_by
      t.timestamps
    end
    add_index :taggings, [:tag_id, :tagged_id], :unique => true
  end
end
