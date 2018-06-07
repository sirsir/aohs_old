class WebTrackingLogController < ApplicationController
  
  before_action :authenticate_user!
  
  def index
    
  end
  
  def call_logging
    
    log = call_log_params 
    cond = {
      user_id: log[:user_id],
      session_id: log[:session_id],
      voice_log_id: log[:voice_log_id]
    }
    
    ctl_count = CallTrackingLog.where(cond).count(:id)
    if ctl_count <= 0
      result = CallTrackingLog.create(log)
    end
    
    render text: 'updated'
  
  end
  
  private
  
  def call_log_params
    return {
      tracking_type:  1,
      user_id: current_user.id,
      voice_log_id: params[:voice_log_id],
      listened_sec: params[:listened_sec],
      request_id: params[:reqid],
      session_id: request.session_options[:id],
      remote_ip: request.remote_ip
    }
  end
  
end
