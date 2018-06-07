class AddKeywordResult < ActiveRecord::Migration
  def change
    add_column :result_keywords, :result,    :string, limit: 50
    add_column :result_keywords, :channel,   :integer
    remove_column :result_keywords, :created_at
  end
end