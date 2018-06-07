class AddFieldEvCriteria < ActiveRecord::Migration
  def change
    add_column  :evaluation_criteria, :na_flag,   :string,  limit: 1
    add_column  :evaluation_criteria, :use_flag,  :string,  limit: 1
  end
end
