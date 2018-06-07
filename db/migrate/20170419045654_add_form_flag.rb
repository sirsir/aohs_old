class AddFormFlag < ActiveRecord::Migration
  def change
    add_column :evaluation_plans, :show_group_flag, :string, limit: 1
  end
end
