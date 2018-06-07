class KeywordsController < ApplicationController

  before_action :authenticate_user!, except: [:keywords]
  layout LAYOUT_MAINTENANCE
  
  def index
    # initial data
    KeywordType.initialize_word_types
    
    # normal process
    page, per = current_or_default_perpage
    @keywords = Keyword.search(conditions_params).result
    @keywords = @keywords.not_deleted.order_by(order_params)
    @keywords = @keywords.page(page).per(per)
  end
  
  def new
    @keyword = Keyword.new
  end

  def create
    @keyword = Keyword.new(keyword_params)
    if @keyword.save
      db_log(@keyword, :new)
      flash_notice(@keyword, :new)
      redirect_to action: "edit", id: @keyword.id
    else
      render action: "new"
    end
  end
  
  def edit
    find_keyword
  end
  
  def update
    find_keyword
    if @keyword.update_attributes(keyword_params) and @keyword.update_word_list(word_list_params)
      db_log(@keyword, :update)
      flash_notice(@keyword, :update)
      redirect_to action: "edit"
    else
      render action: "edit"  
    end
  end
  
  def delete
    rs = "deleted"
    @keyword = Keyword.where(id: keyword_id).first
    if @keyword.can_delete?
      @keyword.do_delete
      @keyword.save
      db_log(@keyword, :delete)
      flash_notice(@keyword, :delete)
    end
    render text: rs
  end
  
  def destroy
    delete
  end
  
  def keywords
    @keywords = Keyword.not_deleted.order(:name).all
    respond_to do |format|
      format.txt
      format.json do
        render json: Keyword.to_setting_data(@keywords)
      end
    end
  end
  
  def list
    keywords = Keyword.select([:id,:name]).root.not_deleted.order(name: :asc)
    if params.has_key?(:q)
      q = params[:q]
      keywords = keywords.where("name LIKE ?","#{q}%")
    end
    data  = keywords.all.map { |g| { id: g.id, name: g.name, text: g.name } }
    render json: data
  end
  
  def settings
    @keyword_types = KeywordType.order_by_default.all
  end
  
  def keyword_type
    keyword_type_id = params[:id]
    @keyword_type = KeywordType.where(id: keyword_type_id).first
  end
  
  private

  def find_keyword
    @keyword = Keyword.where(id: keyword_id).first
  end
  
  def keyword_id
    params[:id]
  end
  
  def keyword_params
    if params[:selected_keyword_type].present?
      type = KeywordType.update_new_type(params[:selected_keyword_type])
      params[:keyword][:keyword_type_id] = type.id
    end
    if notify_params[:desktop_alert].to_s.downcase == "default"
      params[:keyword][:notify_flag] = ""
    else
      params[:keyword][:notify_flag] = "N"
    end

    params[:keyword][:name] = Keyword.replace_tag(params[:keyword][:name])
    params[:keyword][:notify_details] = notify_params.to_json
    params.require(:keyword).permit(
            :name,
            :keyword_type_id,
            :subtype,
            :bg_color,
            :notify_flag,
            :notify_details,
            :detection_settings,
            :parent_id)
  end
  
  def word_list_params
    words = params[:word_list]  
    return words
  end
  
  def notify_params
    data = params[:notify]
    begin
      # compact contents
      data["contents"] = (data["contents"].map { |c| (c.to_s.strip.empty? ? nil : c.to_s.strip) }).compact
      data["contents"] = data["contents"].map { |c| Keyword.replace_tag(c) }
    rescue
    end
    return data
  end
  
  def detection_settings_params
    begin
      return JSON.parse(params[:detection_settings])
    rescue
      return nil
    end
  end
  
  def order_params
    get_order_by(:name,:desc)
  end

  def conditions_params
    conds = {
      parent_id_eq: get_param(:keyword_id),
      name_cont: get_param(:name),
      keyword_type_eq: get_param(:keyword_type),
    }
    unless conds[:keyword_type_eq].blank?
      conds[:keyword_type_eq] = [params[:keyword_type]]
    end
    conds.remove_blank!
  end
  
end
