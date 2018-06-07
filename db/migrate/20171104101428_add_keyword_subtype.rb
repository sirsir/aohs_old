class AddKeywordSubtype < ActiveRecord::Migration
  def change
    add_column :keywords, :subtype, :string, limit: 3
  end
end
