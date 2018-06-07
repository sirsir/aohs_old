class AddFieldCriteria < ActiveRecord::Migration
  def change
    add_column  :evaluation_criteria, :variable_name, :string,  limit: 80
  end
end
