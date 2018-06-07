class PhoneInfosController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    @phones = TelephoneInfo.search(conditions_params).result    
    @phones = @phones.order_by(order_params).page(page).per(per)
  end

  def new
    @phone = TelephoneInfo.new
  end
  
  def create
    @phone = TelephoneInfo.new(phone_params)
    if @phone.save
      db_log(@phone, :new)
      flash_notice(@phone, :new)
      redirect_to action: "edit", id: @phone.id
    else
      render action: "new"
    end
  end
  
  def edit
    find_phone
  end
  
  def update
    find_phone
    if @phone.update(phone_params)
      db_log(@phone, :edit)
      flash_notice(@phone, :edit)
      redirect_to action: "edit", id: @phone.id
    else
      render action: "edit"
    end
  end
  
  def delete
    find_phone
    unless @phone.nil?
      @phone.delete
      db_log(@rule, :delete)
      flash_notice(@rule, :delete)      
    end
    rs = "deleted"
    render text: rs
  end
  
  def destroy
    delete
  end
  
  private

  def phone_params    
    params.require(:telephone_info).permit(:number, :number_type)
  end
  
  def phone_id
    params[:id]
  end
  
  def find_phone
    @phone = TelephoneInfo.where(id: phone_id).first
  end
  
  def conditions_params
    conds = {
      number_cont: get_param(:number)
    }
    conds.remove_blank!
  end
  
  def order_params
    get_order_by(:number)
  end
  
  # end
end
