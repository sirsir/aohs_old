class AutoAssessmentLog < ActiveRecord::Base
  
  serialize :result_log, JSON
  
end