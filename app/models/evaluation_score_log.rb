class EvaluationScoreLog < ActiveRecord::Base
  
  belongs_to  :evaluation_log

  serialize :answer, JSON
  
  scope :find_by_evaluation_log, ->(id){
    where(evaluation_log_id: id)
  }
  
  scope :only_question, ->{
    where.not(evaluation_question_id: 0)
  }

  scope :only_group, ->{
    where(evaluation_question_id: 0)
  }
  
  def filtered_answer
    ans = []
    unless self.answer.nil?
      self.answer.each do |a|
        if a["deduction"] == "uncheck"
          # exclude checkbox (negative)
        else
          ans << a
        end
      end
    end
    return ans
  end  
  
  private
  
  def question_id
    self.evaluation_question_id  
  end
  
  # end class
end
