class EvaluationAnswer < ActiveRecord::Base
  
  serialize :answer_list, JSON
  serialize :ana_settings, JSON
    
end