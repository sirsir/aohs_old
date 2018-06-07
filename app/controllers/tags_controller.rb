class TagsController < ApplicationController

  before_action :authenticate_user!
  
  layout LAYOUT_MAINTENANCE
  
  def index
    
    page, per = current_or_default_perpage
    
    @tags     = Tag.search(conditions_params).result.without_subtags
    @tags     = @tags.order_by(tag_order_parms).page(page).per(per)
    
    if isset_param?(:tag_id) and @tags.length == 1
      
      @tag      = @tags.first
      @sub_tags = Tag.where(parent_id: @tag.id).order_by(tag_order_parms)
      
    end

  end
  
  def new
    
    @tag = Tag.new
    
  end
  
  def create

    @tag = Tag.new(tag_params)
    
    if @tag.save
      
      db_log(@tag, :new)
      flash_notice(@tag, :new)
      
      redirect_to action: "edit", id: @tag.id
      
    else
      
      render action: "new"
    
    end

  end
  
  def edit

    @tag = Tag.where(id: tag_id).first

  end
  
  def update

    tag_id = params[:id]
    
    @tag = Tag.where(id: tag_id).first
    
    if @tag.update_attributes(tag_params)
      
      db_log(@tag, :update)
      flash_notice(@tag, :update)
      
      redirect_to action: "edit"
    
    else
  
      render action: "edit"
    
    end

  end
  
  def delete

    result  = ""
    tag_id = params[:id]
    
    @tag = Tag.where(id: tag_id).first
    
    unless @tag.nil?
      
      if @tag.remove_subtags and @tag.delete
        
        db_log(@tag, :delete)
        flash_notice(@tag, :delete)
        
        result = "deleted"
      end
    end
    
    render text: result
    
  end
  
  def destroy
    
    delete
    
  end

  def autocomplete
    
    tags = Tag.select("id,name").order(name: :asc)
    if params.has_key?(:q)
      q = params[:q]
      tags = tags.where("name LIKE ?","#{q}%")
    end
    
    data = []    
    data = tags.all.map { |t| { id: t.id, name: t.name } }

    render json: data
    
  end
  
  def tag_style
    
    @tags = Tag.all
    
  end
  
  def list

    tags = Tag.select("id,name").order("name")
    if params.has_key?(:q)
      q = params[:q]
      tags = tags.where("name LIKE ?","#{q}%")
    end
    tags = tags.limit(100).all
    
    data  = tags.map { |u| { id: u.id, text: u.name } }
    
    render json: data
    
  end

  private
  
  def tag_id
    
    params[:id].to_i
    
  end
  
  def conditions_params
    
    conds = {
      tag_like:        get_param(:name),
      id_eq:           get_param(:tag_id)
    }
    
    conds.remove_blank!
  
  end
  
  def tag_params
    
    params.require(:tag).permit(:name, :tag_code, :color_code, :parent_id)
    
  end
  
  def tag_order_parms
    
    get_order_by(:name)
    
  end
  
end
