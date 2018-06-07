class CustomDictionariesController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    @words = CustomDictionary.ransack(conditions_params).result
    @words = @words.order_by(order_params).page(page).per(per)
  end
  
  def new
    @word = CustomDictionary.new
  end
  
  def create
    @word = CustomDictionary.new(word_params)
    if @word.save
      db_log(@word, :new)
      flash_notice(@word, :new)
      redirect_to action: "edit", id: @word.id  
    else
      render action: "new"
    end
  end
  
  def edit
    find_word
  end

  def update
    find_word
    if @word.update_attributes(word_params)
      db_log(@word, :update)
      flash_notice(@word, :update)
      redirect_to action: "edit"
    else
      render action: "edit"  
    end
  end
  
  def destroy
    delete
  end
  
  def delete
    find_word
    @word.delete
    db_log(@word, :delete)
    flash_notice(@word, :delete)
    render text: "deleted"
  end

  private
  
  def word_id
    params[:id]
  end
  
  def find_word
    @word = CustomDictionary.where(id: word_id).first
  end
  
  def word_params
    params.require(:custom_dictionary).permit(:word, :spoken_word, :class_map) rescue {}
  end

  def order_params
    get_order_by(:word)
  end
  
  def conditions_params
    conds = {
      word_cont: get_param(:word),
      spoken_word_cont: get_param(:spoken_word),
      class_map_cont: get_param(:class_map)
    }
    conds = conds.remove_blank!
    return conds
  end
  
end
