class EvaluationGradeSettingsController < ApplicationController
  
  before_action :authenticate_user!  
  layout LAYOUT_MAINTENANCE
  
  def index
    @grade_settings = EvaluationGradeSetting.not_deleted.order_by_default.all
  end
  
  def new
    @grade_setting = EvaluationGradeSetting.new
  end
  
  def create
    @grade_setting = EvaluationGradeSetting.new(grade_setting_params)
    if @grade_setting.save
      @score_range = @grade_setting.update_score_range(score_range_params)
      @grade_setting.update_grade_point
      db_log(@grade_setting, :new)
      flash_notice(@grade_setting, :new)
      redirect_to action: "edit", id: @grade_setting.id      
    else
      render action: "new"
    end
  end
  
  def edit
	  get_grade_profile
  end
  
  def update
    get_grade_profile
    if @grade_setting.update_attributes(grade_setting_params)
	    @score_range = @grade_setting.update_score_range(score_range_params)
	    @grade_setting.update_grade_point
      db_log(@grade_setting, :update)
      flash_notice(@grade_setting, :update)
      redirect_to action: "edit"
    else
      render action: "edit"  
    end
  end
  
  def delete
    get_grade_profile
    unless @grade_setting.nil?
      @grade_setting.do_delete
      @grade_setting.save
      db_log(@grade_setting, :delete)
      flash_notice(@grade_setting, :delete)
    end
    render text: "deleted"
  end
  
  def destroy
    delete
  end
  
  private
  
  def setting_id
    params[:id]
  end

  def grade_setting_params
		tmp = score_range_params
    return params.require(:evaluation_grade_setting).permit(:title) rescue {}
  end
  
  def get_grade_profile
    @grade_setting = EvaluationGradeSetting.not_deleted.where(id: setting_id).first
    @score_range = @grade_setting.evaluation_grades.order(upper_bound: :desc).all
  end

  def score_range_params
    ranges = []
    @score_range = []
    titles = params[:form_grade_title]
    up_bounds = params[:form_grade_upper]
    titles.each_with_index do |grade, i|
      next if grade.to_s.empty?
      ranges << {
        title: grade,
        lower_bound: 0,
        upper_bound: up_bounds[i].to_i
      }
      @score_range << EvaluationGrade.new({ name: grade, upper_bound: up_bounds[i].to_i})
    end
    ranges.each_with_index do |r,i|
      next_i = i + 1
      if next_i < ranges.length 
        r[:lower_bound] = ranges[next_i][:upper_bound] + 1
      end
    end
    return ranges
  end
  
end
