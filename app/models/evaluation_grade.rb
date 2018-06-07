class EvaluationGrade < ActiveRecord::Base

  has_paper_trail
  
  default_value_for :flag, ""
  
  belongs_to :evaluation_grade_setting
  
end
