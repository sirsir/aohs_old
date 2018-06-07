class ReviseGradeSettings < ActiveRecord::Migration
  def change
    remove_column :evaluation_grades, :evaluation_plan_id
    add_column :evaluation_grades, :point, :float
  end
end
