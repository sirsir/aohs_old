class CreateAnalyticTemplateMaps < ActiveRecord::Migration
  def change
    create_table :analytic_template_maps do |t|
      t.integer       :template_id,       foreign_key: false
      t.integer       :template_child_id, foreign_key: false
      t.integer       :order_no
      t.timestamps null: false
    end
  end
end
