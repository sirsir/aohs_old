class EvaluationComment < ActiveRecord::Base
  
  FLAG_EVALUATE_CM = 'E'
  FLAG_CHECK_CM = 'C'
  
  belongs_to    :evaluation_log
  
  scope :for_evaluation, ->{
    where(comment_type: FLAG_EVALUATE_CM)  
  }
  
  scope :for_reviewer, ->{
    where(comment_type: FLAG_CHECK_CM)
  }
  
  def self.new_summary_comment
    new({ comment_type: FLAG_EVALUATE_CM })
  end

  def self.new_reviewer_comment
    new({ comment_type: FLAG_CHECK_CM })
  end
  
  def written_by_evaluator?
    self.comment_type == FLAG_EVALUATE_CM  
  end

  def writted_by_reviewer?
    self.comment_type == FLAG_CHECK_CM
  end
  
end
