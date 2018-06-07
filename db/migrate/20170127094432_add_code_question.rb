class AddCodeQuestion < ActiveRecord::Migration
  def change
    add_column :evaluation_questions, :code_name, :string, limit: 50
  end
end
