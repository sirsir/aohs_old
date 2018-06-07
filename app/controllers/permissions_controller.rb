class PermissionsController < ApplicationController
  
  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    params[:per]  = Settings.pagination.per_roles.to_s
    page, per     = current_or_default_perpage
    
    @roles        = Role.not_deleted.order("name").page(page).per(per)
    @privileges   = Privilege.exclude_disabled_function.select("DISTINCT module_name, category").order_specific_vals.all
    @categories   = Privilege::CATEGORIES.reverse
  end
  
  def update_permission
    permission = Permission.where(update_params).first
    if permission.nil? and is_permission_checked?
      permission = Permission.new(update_params)
      permission.save
      db_log(permission, :new)
    else
      unless permission.nil?
        db_log(permission, :delete)
        permission.delete
      end
    end
    clear_cache_permission
    render text: "updated"
  end
  
  protected
  
  def update_params
    privilege_id  = params[:privilege_id].to_i
    role_id       = params[:role_id].to_i  
    return {
      privilege_id: privilege_id,
      role_id:      role_id
    }
  end
  
  def is_permission_checked?
    return (params[:checked] == "true")
  end
 
  def clear_cache_permission
    Rails.cache.delete_matched(/^(privilege_of_)(.+)/)
    Rails.cache.delete_matched(/^(permission_of_)(.+)/)
  end
  
end
