class CreateAutoAssessmentLogs < ActiveRecord::Migration
  def change
    create_table :auto_assessment_logs do |t|
      t.integer   :voice_log_id,            limit: 8, null: false, foreign_key: false
      t.integer   :evaluation_plan_id,      foreign_key: false 
      t.integer   :evaluation_question_id,  foreign_key: false
      t.integer   :evaluation_answer_id,    foreign_key: false
      t.string    :result,                  limit: 50
      t.string    :result_log,              limit: 250
      t.string    :flag,                    limit: 1
      t.datetime  :created_at
    end
    add_index :auto_assessment_logs, :voice_log_id, name: 'index_voice_log'
  end
end
