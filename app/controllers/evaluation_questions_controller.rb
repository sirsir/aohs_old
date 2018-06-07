class EvaluationQuestionsController < ApplicationController

  before_action :authenticate_user!  
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    @question_groups = EvaluationQuestionGroup.not_deleted.order(:title).all
    @questions = EvaluationQuestion.ransack(conditions_params).result
    @questions = @questions.not_deleted.order_by(order_params).page(page).per(per)
  end

  def new
    @question = EvaluationQuestion.new
    @answer = EvaluationAnswer.new
    @answer.do_init
    if layout_blank?
      render layout: 'blank'
    end
  end
  
  def create
    @question = EvaluationQuestion.new(question_params)
    @answer = EvaluationAnswer.new(answer_params)
    if @question.save
      @answer.evaluation_question_id = @question.id
      @answer.do_init
      if @answer.save
        db_log(@question, :new)
        flash_notice(@question, :new)
        redirect_to action: "edit", id: @question.id, lyt: params[:lyt]
      else
        # something wrong
        redirect_to action: "edit", id: @question.id, lyt: params[:lyt]
      end
    else
      unless layout_blank?
        render action: :new
      else
        render layout: 'blank', action: :new 
      end
    end
  end
  
  def edit
    find_question
    if layout_blank?
      render layout: 'blank'
    end
  end
  
  def update
    find_question
    if @question.update_attributes(question_params)
      @old_answer = @answer
      @answer = EvaluationAnswer.new(answer_params)
      @answer.evaluation_question_id = @question.id
      @answer.do_init
      if @answer.has_changed?(@old_answer) and @answer.save
        @old_answer.do_delete
        @old_answer.save
      end
      db_log(@question, :update)
      flash_notice(@question, :update)
      redirect_to action: "edit", id: @question.id, lyt: params[:lyt]
    else
      render action: "edit"
    end
  end
  
  def destroy
    delete
  end
  
  def delete
    find_question
    unless @question.nil?
      @question.do_delete
      @question.save  
    end
    unless @answer.nil?
      @answer.do_delete
      @answer.save  
    end
    render text: 'deleted'
  end

  def create_group
    group_title = params[:title]
    result = EvaluationQuestionGroup.create_if_not_exist(group_title)
    unless result.nil?
      db_log(result, :new)
      render json: { id: result.id, title: result.title }
    else
      render json: { result: false }
    end
  end
  
  def update_group
    group_question = EvaluationQuestionGroup.where(id: params[:id]).first
    unless group_question.nil?
      group_question.title = params[:title]
      if group_question.save
        db_log(group_question, :update)
        flash_notice(group_question, :update)
        render json: { errors: [] }
      else
        render json: { errors: group_question.errors.full_messages }
      end
    else
      render json: { errors: ["Invalid ID"] }
    end
  end
  
  def delete_group
    group_question = EvaluationQuestionGroup.where(id: params[:id]).first
    unless group_question.nil?
      
    end
    render json: { errors: [] }
  end
  
  def group_options
    select_name = params[:select]
    result = EvaluationQuestionGroup.select_options({ includes: [select_name] })
    render json: result.to_json
  end

  private
  
  def question_id
    params[:id]
  end
  
  def find_question
    @question = EvaluationQuestion.where(id: question_id).first
    @answer = @question.evaluation_answers.last_version.first
  end
  
  def order_params
    get_order_by(:title)
  end
  
  def conditions_params
    conds = {
      title_cont: get_param(:title),
      question_group_id_eq: get_param(:question_group_id)
    }
    conds = conds.remove_blank!
    return conds
  end

  def question_params
    params.require(:evaluation_question).permit(:title, :question_group_id, :report_title, :code_name) rescue {}
  end

  def answer_params
    return {
      answer_type: params[:answer_type],
      answer_list: choice_params,
      ana_settings: assessment_params
    }
  end
  
  def choice_params
    choices = []
    case params[:answer_type]
    when "numeric"
      choices << {
        min_score: 0,
        max_score: params[:answer_score].to_f 
      }
    else
      titles = params[:answerlist_title]
      values = params[:answerlist_value]
      notes = params[:answerlist_note]
      ana_rules = params[:answerlist_ana_rules]
      cmt_require = params[:answerlist_cmmt]
      if not titles.blank? and not values.blank?
        titles.each_with_index do |title, i|
          choices << {
            title: title.to_s.strip,
            score: values[i].to_f,
            note: notes[i].to_s.strip,
            require_comment: (cmt_require[i] == "Y"),
            rules: (JSON.parse(ana_rules[i]) rescue nil)
          }
        end
      end
    end
    return choices
  end
  
  def assessment_params
    return {
      engine_name: params[:engine_name].to_s,
      rule_name: params[:rule_name].to_s,
      parameters: params[:rule_parameters].to_s
    }  
  end

  def layout_blank?
    return (params[:lyt] == "blank")
  end
  
end
