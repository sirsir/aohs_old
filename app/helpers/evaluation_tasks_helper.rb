module EvaluationTasksHelper
  
  def schedule_mode?
    return params["mode"] == "schedule"
  end
  
  def schedule_task?
    schedule_mode?
  end
  
  def unassign_mode?
    params[:mode] == "unassign"  
  end
  
  def reassign_mode?
    params[:mode] == "reassign"
  end
  
end
