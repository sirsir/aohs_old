class CreateAnalyticTemplates < ActiveRecord::Migration
  def change
    create_table :analytic_templates do |t|
      t.string        :title,         limit: 200
      t.string        :speaker_type,  limit: 1, null: false, default: ""
      t.string        :flag,          limit: 1, null: false, default: ""
      t.string        :match_range   
      t.timestamps null: false
    end
    add_column  :evaluation_criteria, :analytic_template_id,   :integer
  end
end
