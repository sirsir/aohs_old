class ApplicationController < ActionController::Base
  
  protect_from_forgery
  
  include AuthenticatedSystem
  include AmiPermission
  include AmiLog
  include Format

  before_filter :initial_config
  
  def initial_config
    
    $CF = AmiConfig::UserConf.new(session[:user_id])
    $PER_PAGE = $CF.get('client.aohs_web.number_of_display_list').to_i
    $SERVER_ROOT_URL = Aohs::SITE_ROOT
    
    ## fixed
    AmiTool.switch_table_voice_logs
    
  end
    
end
