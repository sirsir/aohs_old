class EvaluationPlansController < ApplicationController
  
  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE

  def index
    page, per = current_or_default_perpage
    @plans = EvaluationPlan.ransack(conditions_params).result
    @plans = @plans.not_deleted.order_by(order_params).page(page).per(per)
  end
  
  def new
    @evaluation_plan = EvaluationPlan.new
  end
  
  def create
    @evaluation_plan = EvaluationPlan.new(evaluation_plan_params)
    if @evaluation_plan.save
      db_log(@evaluation_plan, :new)
      flash_notice(@evaluation_plan, :new)
      redirect_to action: "edit", id: @evaluation_plan.id
    else
      render action: :new
    end
  end
  
  def edit
    get_form
    get_groups_and_questions
    get_assts
  end

  def update
    get_form
    get_groups_and_questions
    get_assts
    
    if @evaluation_plan.update_attributes(evaluation_plan_params)
      @evaluation_plan.update_criteria(question_params)
      @evaluation_plan.update_asst_settings(call_selector_params)
      @evaluation_plan.update_actions(form_action_params)
      if params[:other].present? and params[:other][:show_group_flag] == "show"
        @evaluation_plan.show_group_flag = "Y"
      else
        @evaluation_plan.show_group_flag = "N"
      end
      if params[:other].present? and params[:other][:comment_flag] == "yes"
        @evaluation_plan.comment_flag = "Y"
      else
        @evaluation_plan.comment_flag = "N"
      end
      @evaluation_plan.save
      
      # reset order no
      EvaluationQuestionGroup.auto_update_order_no
      EvaluationQuestion.auto_update_order_no
      
      db_log(@evaluation_plan, :update)
      flash_notice(@evaluation_plan, :update)
      
      redirect_to action: "edit", id: @evaluation_plan.id 
    else
      render action: "edit"
    end
  end
  
  def delete
    get_form
    
    if not @evaluation_plan.nil?
      @evaluation_plan.do_delete
      @evaluation_plan.save
      
      db_log(@evaluation_plan, :delete)
      flash_notice(@evaluation_plan, :delete)
    end
    
    render json: { result: 'deleted' }
  end
    
  def destroy
    delete
  end
  
  def group_and_questions
    get_form
    get_groups_and_questions
    render json: { question_groups: @question_groups }
  end
  
  def list
    forms = EvaluationPlan.select([:id,:name]).not_deleted.order(:name)
    if params.has_key?(:q)
      forms = forms.find_by_title(params[:q])
    end
    data = forms.all.map { |t|
      { id: t.id, name: t.name, text: t.name }
    }
    render json: data  
  end
  
  private
  
  def plan_id
    params[:id]
  end
  
  def get_form
    @evaluation_plan = EvaluationPlan.where(id: plan_id).first
    unless defined? @form_actions
      @form_actions = @evaluation_plan.get_rules
    end
  end
  
  def get_groups_and_questions
    @question_groups = []
    
    custom_groups = @evaluation_plan.evaluation_criteria.only_category.not_deleted.all.to_a
    custom_quests = @evaluation_plan.evaluation_criteria.only_criteria.not_deleted.all.to_a
    
    quest_groups = EvaluationQuestionGroup.order_by_default.all
    quest_groups.each do |qg|
      fgroup = (custom_groups.select { |x| x.question_group_id == qg.id }).first
      if qg.deleted?
        next if fgroup.nil?
      end
      # question / criteria
      quests = []
      qg.evaluation_questions.order_by_default.all.each do |q|
        fquest = (custom_quests.select { |x| x.evaluation_question_id == q.id }).first
        if q.deleted?
          next if fquest.nil?
        end
        ans = q.evaluation_answers.last_version.first
        quests << {
          id: q.id,
          title: q.title,
          code: q.code_name,
          answer_type: ans.display_answer_type,
          max_score: ans.max_score,
          selected: (fquest.nil? ? false : true),
          order_no: (fquest.nil? ? 999 : fquest.order_no),
          deleted_css: ((q.deleted? or qg.deleted?) ? "q-deleted" : "q-not-delete")
        }
      end
      # group
      next if quests.empty?
      quests = quests.sort { |x,y| x[:order_no] <=> y[:order_no] }
      @question_groups << {
        id: qg.id,
        title: qg.title,
        questions: quests,
        selected: (fgroup.nil? ? false : true),
        weighted: (fgroup.nil? ? 0 : fgroup.weighted_score.to_i),
        order_no: (fgroup.nil? ? 999 : fgroup.order_no),
        deleted_css: (qg.deleted? ? "q-deleted" : "q-not-delete")
      }
    end
    # sort
    @question_groups = @question_groups.sort { |x,y| x[:order_no] <=> y[:order_no] }
  end
  
  def get_assts
    @asst_settings = {}
    assts = @evaluation_plan.call_settings
    unless assts.nil?
      @asst_settings = assts
    end
  end
  
  def evaluation_plan_params
    params.require(:evaluation_plan).permit(:name, :description, :evaluation_grade_setting_id, :order_no) rescue {}
  end
  
  def question_params
    quest_groups = []
    
    q_groups = params[:question_group_select]
    q_orders = params[:question_group_orderno]
    q_groups.each do |group_id, is_select|
      next unless is_select == "true"
      qg = EvaluationQuestionGroup.where(id: group_id).first
      rs = {
        id: qg.id,
        type: 'category',
        title: qg.title,
        weighted_score: 0,
        order_no: q_orders[group_id].to_i,
        questions: []
      }
      
      quests = params[:question_select]
      quorder = params[:question_orderno]
      quests.each do |quest_id, is_select2|
        next unless is_select2 == "true"
        qu = EvaluationQuestion.where(id: quest_id).first
        next unless qg.id == qu.question_group_id
        rs[:questions] << {
          id: qu.id,
          type: 'criteria',
          title: qu.title,
          order_no: quorder[quest_id].to_i,
          group_order_no: q_orders[group_id].to_i
        }
      end
      
      quest_groups << rs
    end
    
    return quest_groups
  end
  
  def call_selector_params
    pams = {}
    if params[:asst].present?
      p = params[:asst]
      # call direction
      if p[:call_direction].present?
        pams[:call_direction] = p[:call_direction]
      end
      # min duration
      if p[:min_duration].present? and p[:min_duration].to_i > 0
        pams[:min_duration] = p[:min_duration].to_i
      end
      # call_types
      if p[:category].present?
        pams[:call_category] = []
        p[:category].each do |cate_type,types|
          pams[:call_category] << types
        end
      end
      # auto assessment enable
      pams[:enable_auto_asst] = false
      if p[:enable_auto_asst].present? and p[:enable_auto_asst] == "enable"
        pams[:enable_auto_asst] = true
      end
    end
    return pams
  end
  
  #def auto_asst_params
  #  assts = []
  #  if params[:asst].present?
  #    p_asst = params[:asst]
  #    asst = {}
  #    if p_asst[:call_direction].present?
  #      asst[:call_direction] = p_asst[:call_direction]
  #    end
  #    if p_asst[:enable_auto_asst].present? and p_asst[:enable_auto_asst] == "enable"
  #      asst[:enable] = true
  #    else
  #      asst[:enable] = false
  #    end
  #    if p_asst[:min_duration].present? and p_asst[:min_duration].to_i > 0
  #      asst[:min_duration] = p_asst[:min_duration].to_i  
  #    end
  #    if p_asst[:call_category].present?
  #      asst[:call_category] = []
  #      p_asst[:call_category].each do |cc|
  #        asst[:call_category] << cc.to_i  
  #      end
  #    end
  #    assts << asst if asst.length > 0
  #  end
  #  return assts
  #end

  def form_action_params
    # action/rule params
    @form_actions = []
    if params[:rule_name].present?
      # action||id
      rules = params[:rule_name]
      titles = params[:rule_title]
      cond = params[:rule_condition]
      rules.each_with_index do |rl,i|
        rx = rl.split("||")
        @form_actions << {
          action: rx[0],
          target_id: rx[1],
          condition: cond[i]
        }
      end
    end
    return @form_actions
  end
  
  def order_params  
    get_order_by(:name)
  end
  
  def conditions_params
    conds = {
      name_cont: get_param(:name),
      evaluation_grade_setting_id_eq: get_param(:grade)
    }
    conds = conds.remove_blank!
    return conds    
  end
  
  # end class
end
