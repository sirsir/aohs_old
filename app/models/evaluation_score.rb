class EvaluationScore < ActiveRecord::Base

  has_paper_trail
  
  belongs_to  :evaluation_criterium, foreign_key: "evaluation_criteria_id"

  scope :not_deleted, ->{
    where.not({flag: DB_DELETED_FLAG})  
  }
  
end
