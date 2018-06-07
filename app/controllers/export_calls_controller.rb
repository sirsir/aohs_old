class ExportCallsController < ApplicationController

  before_action :authenticate_user!

  layout LAYOUT_MAINTENANCE
  
  def index
    
    @tasks = ExportTask.search(conditions_params).result.not_deleted
    @tasks = @tasks.order_by(task_order).all
    
  end
  
  def new
    
    @task = ExportTask.new
    
  end
  
  def create
    
    @task = ExportTask.new(task_new_params)
    @task.set_state
    
    if @task.save

      db_log(@task, :new)
      flash_notice(@task, :new)
      
      redirect_to action: "edit", id: @task.id
      
    else
      
      render action: "new"

    end
    
  end

  def edit
    
    @task = ExportTask.where(id: params[:id]).first
    
  end

  def update
    
    result = {}
    
    @task = ExportTask.where(id: params[:id]).first
    
    if @task.update_attributes(taks_update_params)
      @task.update_conditions(condition_params)
      @task.save
    else
      result[:errors] = @task.errors
    end

    render json: result
    
  end
  
  def delete
    
    result = { deleted: true }
    
    @task = ExportTask.where(id: params[:id]).first
    unless @task.nil?
      @task.do_delete
      @task.save
    end
    
    render json: result
    
  end

  def destroy
    delete
  end
  
  def show
  
    @task = ExportTask.where({ id: params[:id] }).first
    @result_logs = @task.export_logs.order({ updated_at: :desc})
    
  end
  
  private
  
  def task_new_params
    
    params.require(:export_task).permit(
            :name,
            :category,
            :schedule_type,
            :desc)

  end
  
  def taks_update_params

    return {
      name: params[:name],
      category: params[:category],
      desc: params[:description],
      filename: params[:filename],
      audio_type: params[:audio_type],
      compression_type: params[:compress_type]
    }
    
  end

  def condition_params
    
    cond_string = params[:export_condition]
    return JSON.parse(cond_string)    
  
  end

  def conditions_params
    
    conds = {
      name_cont:        get_param(:title),
      schedule_type_eq: get_param(:type),
      category_cont:    get_param(:category)
    }
    
    conds = conds.remove_blank!

    return conds
    
  end
  
  def task_order
    
    get_order_by(:name)
  
  end

end
