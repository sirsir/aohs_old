class CreateKeywords < ActiveRecord::Migration
  def self.up
    create_table :keywords do |t|
      t.string :name
	  t.text :match_string
      t.string :keyword_type
      t.timestamps
    end
  end

  def self.down
    drop_table :keywords
  end
end
