class CreateAnalyticPatterns < ActiveRecord::Migration
  def change
    create_table :analytic_patterns do |t|
      t.integer       :analytic_template_id,    null: false, foreign_key: false
      t.text          :pattern
      t.string        :pattern_type
      t.timestamps null: false
    end
  end
end
