class CallCategoriesController < ApplicationController

  before_action :authenticate_user!
  
  layout LAYOUT_MAINTENANCE
  
  def index
    @call_categories = CallCategory.not_deleted.order_by(order_params).all
  end
  
  def new
    @call_category = CallCategory.new
  end
  
  def create
    @call_category = CallCategory.new(call_category_params)
    if @call_category.save
      db_log(@call_category, :new)
      flash_notice(@call_category, :new)
      redirect_to action: "edit", id: @call_category.id      
    else
      render action: "new"
    end
  end
  
  def edit
    @call_category = CallCategory.not_deleted.where(id: call_category_id).first
  end

  def update
    @call_category = CallCategory.where(id: call_category_id).first
    if @call_category.update_attributes(call_category_params)
      db_log(@call_category, :update)
      flash_notice(@call_category, :update)
      redirect_to action: "edit"
    else
      render action: "edit"  
    end
  end
  
  def delete
    @call_category = CallCategory.where(id: call_category_id).first
    unless @call_category.nil?
      @call_category.do_delete
      @call_category.save
      db_log(@call_category, :delete)
      flash_notice(@call_category, :delete)
    end
    render text: "deleted"
  end
  
  def destroy
    delete
  end
  
  def list
    cates = CallCategory.not_deleted.select([:id,:title]).order_by_default
    data = cates.map { |r|
      { id: r.id, text: r.title }
    }
    render json: data
  end
  
  def types
    @types = CallCategory.defined_type.select("category_type, GROUP_CONCAT(title) AS titles").group(:category_type).order(:category_type).all
  end
  
  def update_types
    if params.has_key?(:types)
      updated_types = []
      cate_types = params[:types].values
      cate_types.each do |type|
        ct = CallCategoryType.where(title: type[:type], order_no: type[:order_key].to_i).first
        if ct.nil?
          ct = CallCategoryType.new(title: type[:type], order_no: type[:order_key].to_i)
        end
        ct.parent_id = 0
        ct.save
        updated_types << ct.id
      end
      CallCategoryType.where.not(id: updated_types).delete_all
    end
    render json: { errors: [] }
  end
  
  private

  def call_category_id
    params[:id]
  end
  
  def call_category_params
    params.require(:call_category).permit(:title, :category_type, :code_name, :fg_color) rescue {}
  end

  def order_params  
    get_order_by(:title)
  end

end
