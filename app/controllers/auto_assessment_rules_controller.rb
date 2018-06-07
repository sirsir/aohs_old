class AutoAssessmentRulesController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage

    @rules = AutoAssessmentRule.search(conditions_params).result    
    @rules = @rules.not_deleted.order_by(order_params)
    @rules = @rules.page(page).per(per)
  end
  
  def new
    @rule = AutoAssessmentRule.new
  end
  
  def create
    @rule = AutoAssessmentRule.new(asst_rule_params)
    @rule.do_init
    if @rule.save
      @rule.rule_options = rule_options_params
      @rule.save
      db_log(@rule, :new)
      flash_notice(@rule, :new)
      
      redirect_to action: "edit", id: @rule.id
    else
      render action: "new"
    end
  end
  
  def edit
    find_rule
  end
  
  def update
    find_rule
    if @rule.update(asst_rule_params)
      @rule.rule_options = rule_options_params
      @rule.save
      
      db_log(@rule, :edit)
      flash_notice(@rule, :edit)
      redirect_to action: "edit", id: @rule.id
    else
      render action "edit"
    end
  end
  
  def delete
    find_rule
    rs = "deleted"
    if @rule.can_delete?
      @rule.do_delete
      @rule.save
      db_log(@rule, :delete)
      flash_notice(@rule, :delete)
    end
    render text: rs
  end
  
  def destroy
    delete
  end
  
  private
  
  def rule_id
    params[:id]
  end

  def find_rule
    @rule = AutoAssessmentRule.where(id: rule_id).first
  end
  
  def asst_rule_params    
    params.require(:auto_assessment_rule).permit(
            :name,
            :display_name,
            :rule_type)
  end
  
  def rule_options_params
    options = {}
    if params.has_key?(:rule_options) and not params[:rule_options].blank?
      options = params[:rule_options]
    end
    return options.to_json
  end
  
  def conditions_params
    conds = {
      display_name_cont:  get_param(:name),
    }
    conds.remove_blank!
  end
  
  def order_params
    {}
  end
  
end
