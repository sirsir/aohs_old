class EvaluationCriteriaDisplay < ActiveRecord::Base

  self.table_name = "evaluation_criteria_display"
  
  scope :by_form, ->(p){
    where({ evaluation_plan_id: p })
  }
  
  scope :by_criteria, ->(p){
    where("c1_id IN (:id) OR c2_id IN (:id)", id: p ).order("c1_no, c2_no, c3_no")
  }
  
  def category_id
    
    if not self.c3_id.nil?
      return self.c3_id
    elsif not self.c2_id.nil?
      return self.c2_id
    else
      return self.c1_id
    end
    
  end
  
end