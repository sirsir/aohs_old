class EvaluationCriteriaController < ApplicationController

  before_action :authenticate_user!
  
  def update
    # nothing
  end
  
  def list
    get_evaluation_plan
    
    pams = {
      voice_log_id: voice_log_id
    }
    
    result = {
      plan_id: @evaluation_plan.id,
      data: @evaluation_plan.criteria(pams),
      show_group_question: @evaluation_plan.show_group_question?,
      use_only_summary_comment: @evaluation_plan.use_only_comment_summary?,
      revision_no: @evaluation_plan.current_revision_no
    }
    
    render json: result
  end
  
  private
  
  def plan_id
    params[:evaluation_plan_id]  
  end
  
  def voice_log_id
    params[:voice_log_id]
  end
  
  def get_evaluation_plan
    @evaluation_plan = EvaluationPlan.where(id: plan_id).first 
  end
  
end
