class AddKeywordChannel < ActiveRecord::Migration
  def change
    add_column  :keywords, :channel_type, :string,  limit: 1
  end
end
