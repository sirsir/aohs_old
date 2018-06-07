class AnalyticPattern < ActiveRecord::Base
  
  belongs_to  :analytic_template
  
  scope :by_type, ->(type){
    where(pattern_type: type)      
  }

  scope :match_text, ->{
    by_type('match')   
  }

  scope :similar_text, ->{
    by_type('similar')   
  }
  
end
