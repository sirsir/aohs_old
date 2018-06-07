class EvaluationTasksController < ApplicationController
  
  # evaluation task mean assignment task for evaluation
  
  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    @tasks = EvaluationTask.not_deleted.all
  end

  def new
    @task = EvaluationTask.new
    @task.task_type(params[:mode])
    init_assignment
  end
  
  def create
    render action: "index"
  end
  
  def edit
    get_task
    init_assignment
  end
  
  def update
    render action: "index"
  end

  def delete
    get_task
    @task.do_delete
    @task.save
    render json: { result: 'deleted' }
  end
  
  def destroy
    delete
  end
  
  def change_task_status
    get_task
    unless @task.nil?
      is_enable = ((params[:enable] == "false") ? false : true)
      if is_enable
        @task.do_enable
      else
        @task.do_disable 
      end
      @task.save
    end
    render json: { enable: @task.schedule_enabled? }
  end
  
  def query
    ret = {}
    
    task = EvaluationTask.new
    if params[:task_id].present?
      task = EvaluationTask.where(id: params[:task_id]).first
    end
    task.add_options(params[:task])
    task.add_options({ "assigned_by" => current_user.id })
   
    unless task.schedule_task?
      case params[:step]
      when "checkdata"
        ret[:new_assignment_summary] = task.get_new_assignment_info
      when "checkassign"
        ret[:assign_user_summary] = task.get_new_assigned_users
      when "submittask"
        ret[:task] = task.create_or_update_task
        task.create_assignment
        task.do_delete
        task.save
      end
    else
      case params[:step]
      when "submittask"
        ret[:task] = task.create_or_update_task
        task.save
      end
    end
    
    render json: ret
  end
  
  def query_assigned
    ret = {}
    
    task = EvaluationTask.new
    task.add_options(params[:task])
    
    case params[:step]
    when "checkassigned"
      ret[:assigned_summary] = task.check_assigned_summary
    when "dounassign"
      ret[:unassigned_summary] = task.unassign_tasks
    end
    
    render json: ret
  end
  
  def change_assignee
    v_ids = params[:voice_logs_id]
    assignee_id = params[:assignee].to_i
    
    unless v_ids.empty?
      found_tasks = EvaluationAssignedTask.only_pending.by_voice_logs(v_ids).all
      found_tasks.each do |ft|
        ft.reassign_to(assignee_id)
      end
    end
    
    render json: { result: 'success' }
  end
  
  private

  def task_id
    params[:id].to_i
  end
  
  def get_task
    @task = EvaluationTask.where(id: task_id).first
    if params[:action] == "edit" and params[:mode].blank?
      redirect_to action: :edit, id: @task.id, mode: @task.task_type
    end
  end
  
  def init_assignment
    # pending count
    pending_task_count = EvaluationAssignedTask.get_current_pending_stats.to_a
    
    # list of evaluators
    @assigned_users = []
    begin
      @assigned_users = @task.task_options["assign_users"].map { |u| u.to_i }
    rescue
    end
    
    @evaluators = User.evaluator.select(:id, :login, :full_name_th, :full_name_en).all
    @evaluators = @evaluators.map { |u|
      p_count = (pending_task_count.select { |x| x.user_id == u.id }).first
      p_count = (p_count.nil? ? 0 : p_count.pending_count)
      {
        id: u.id, display_name: u.display_name,
        pending_count: p_count,
        selected: (@assigned_users.include?(u.id))
      }
    }

  end
  
end
