class SystemInfoController < ApplicationController
  
  layout LAYOUT_MAINTENANCE
  before_action :authenticate_user!, except: [:check]
  
  def index
    redirect_to action: 'app_info'
  end
  
  def tables
    @tbl_infos = get_tables_info
  end
  
  def tools
    # nothing
  end

  def schedule
    @result = get_sch_info
  end
  
  def check
    found_count = 0
    if session["warden.user.user.session"].present?
      begin
        unq_session_id = session["warden.user.user.session"]["unique_session_id"]
        user_id = session["warden.user.user.key"][0][0]
        found_count = User.only_active.where({ id: user_id, unique_session_id: unq_session_id }).count(0)
      rescue => e
        Rails.logger.warn "Failed to check session data. #{session["warden.user.user.session"].inspect}"
      end
    end
    
    ret = {
      login_required: (found_count <= 0),
      time: Time.now.to_formatted_s(:web)
    }
    
    render json: ret
  end
  
  private
  
  def get_tables_info
    orders = "(data_length+index_length) DESC"
    return TableInfo.order(orders).all
  end
  
  def get_sch_info
    orders = "last_processed_time"
    return ScheduleInfo.order(orders).all
  end

end
