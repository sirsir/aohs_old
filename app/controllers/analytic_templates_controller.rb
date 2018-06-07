class AnalyticTemplatesController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    
    @template = AnalyticTemplate.ransack(conditions_params).result
    @template = @template.page(page).per(per)
  end
  
  def new
    @template = AnalyticTemplate.new
  end

  def create
    @template = AnalyticTemplate.new(template_params)
    if @template.save
      db_log(@template, :new)
      flash_notice(@template, :new)
    
      redirect_to action: "edit", id: @template.id  
    else
      render action: "new"
    end
  end

  def edit
    get_template
  end

  def update
    get_template
    if @template.update_attributes(template_edit_params)
      @template.update_text_match(text_match_params)
      @template.update_text_similar(text_similar_params)
      db_log(@template, :update)
      flash_notice(@template, :update)

      redirect_to action: "edit"
    else
      render action: "edit"  
    end
  end
  
  def delete
    get_template
  end
  
  private
  
  def get_template
    @template = AnalyticTemplate.where(id: template_id).first
    @text_matchs = @template.analytic_patterns.match_text.all
    @text_similars = @template.analytic_patterns.similar_text.all
  end
  
  def conditions_params
    {}
  end
  
  def order_params
    {}
  end
  
  def template_id
    params[:id]
  end
  
  def template_params
    params.require(:analytic_template).permit(:title) rescue {}
  end

  def template_edit_params
    params.require(:analytic_template).permit(:title, :speaker_type) rescue {}
  end

  def text_match_params
    params[:textmatch].uniq.sort rescue []
  end

  def text_similar_params
    params[:textsimilar].uniq.sort rescue []
  end
  
end
