class AddKeywordProp < ActiveRecord::Migration
  def change
    add_column :keywords, :bg_color,    :string, limit: 10
    add_column :keywords, :fg_color,    :string, limit: 10
    change_column :keywords, :keyword_type, :integer
    rename_column :keywords, :keyword_type, :keyword_type_id
  end
end
