class ApplicationController < ActionController::Base
  
  include SysLogger::ActionLog
  include SysPermission::ActionPermission
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  before_action :action_init, :permission_require
  
  protect_from_forgery #with: :exception
  
  def action_init
    init_current_user
    init_default_gon
  end
  
  private
  
  def init_current_user
    @current_usr_id   = 0
    @current_usr_name = "Guest"
    if user_signed_in? and current_user
      @current_usr_id   = current_user.id
      @current_usr_name = current_user.login
    end
  end
  
  def logged_as_admin?
    (current_user and current_user.is_admin?)
  end
  
  def user_for_paper_trail
    user_signed_in? ? current_user.login : 'Guest'
  end
  
  def init_default_gon
    gon.push({
      params: params.select { |k,v| v.is_a?(String) },
      req: {
        id: request.uuid
      }
    })
  end
  
end
