class AssignmentsController < ApplicationController

  before_action :authenticate_user!
  
  def index
    
  end

  def query
    data = {}
    
    data[:assigned] = {}
    data[:assigned][:list] = []
    tasks = EvaluationAssignedTask.only_pending.by_assignee(current_user.id).all
    tasks.each do |t|
      data[:assigned][:list] << {
        id: t.id,
        assigned_at: t.assigned_at.to_formatted_s(:web),
        c_voice_log_id: t.content.voice_log_id,
        c_datetime: t.content.call_datetime_s,
        c_agent_name: t.content.agent_name,
        c_extension: t.content.extension,
        c_duration_s: t.content.duration_s
      }
    end
    
    data[:closed] = {}
    data[:closed][:list] = []
    tasks = EvaluationAssignedTask.only_closed_or_evaluated.by_assignee(current_user.id).within_closed_time.all
    tasks.each do |t|
      data[:closed][:list] << {
        id: t.id,
        assigned_at: t.assigned_at.to_formatted_s(:web),
        c_voice_log_id: t.content.voice_log_id,
        c_datetime: t.content.call_datetime_s,
        c_agent_name: t.content.agent_name,
        c_extension: t.content.extension,
        c_duration_s: t.content.duration_s
      }
    end
    
    # chart data
    data[:chart_mytask_summary] = { data: [], labels: [], colors: [], colors_bd: [] }
    data[:chart_mytask_summary][:labels] << "Assigned"
    data[:chart_mytask_summary][:colors] << "rgba(52, 152, 219, 0.3)"
    data[:chart_mytask_summary][:colors_bd] << "rgb(52, 152, 219)"
    data[:chart_mytask_summary][:data] << data[:assigned][:list].length
    data[:chart_mytask_summary][:labels] << "Closed"
    data[:chart_mytask_summary][:colors] << "rgba(118, 215, 196, 0.3)"
    data[:chart_mytask_summary][:colors_bd] << "rgb(118, 215, 196)"
    data[:chart_mytask_summary][:data] << 0
    
    render json: data
  end
  
  private
  
end
