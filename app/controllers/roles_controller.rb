class RolesController < ApplicationController
  
  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    @roles = Role.not_deleted.order_by(role_order).all
  end
  
  def new
    @role = Role.new
  end
  
  def create
    @role = Role.new(role_params)
    if @role.save
      db_log(@role, :new)
      Role.update_admin_priority
      flash_notice(@role, :new) 
      redirect_to action: "edit", id: @role.id
    else
      render action: "new"
    end
  end
  
  def edit
    @role = Role.where(id: role_id).first
  end
  
  def update
    @role = Role.where(id: role_id).first
    if @role.update(role_params)
      db_log(@role, :update)
      flash_notice(@role, :update) 
      redirect_to action: "edit"  
    else
      render action: "edit"
    end
  end
  
  def delete
    result  = "deleted"
    @role   = Role.where(id: role_id).first
    if not @role.nil? and @role.can_delete?
      @role.do_delete
      @role.save
      db_log(@role, :delete)
      flash_notice(@role, :delete)
    end
    render text: result
  end
  
  def destroy
    delete
  end
  
  private
  
  def role_id
    params[:id].to_i
  end
  
  def role_params
    params.require(:role).permit(:name, :desc, :priority_no, :level, :ldap_dn, :landing_page)
  end
  
  def role_order
    get_order_by(:name)
  end
  
end
