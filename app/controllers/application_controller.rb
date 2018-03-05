class ApplicationController < ActionController::Base
  
  protect_from_forgery
  
  include AuthenticatedSystem
  include AmiPermission
  include AmiLog
  include Format

  before_filter :initial_config

  before_filter :sql_injection
  
  def initial_config
    
    $CF = AmiConfig::UserConf.new(session[:user_id])
    $PER_PAGE = $CF.get('client.aohs_web.number_of_display_list').to_i
    $SERVER_ROOT_URL = Aohs::SITE_ROOT
    
    ## fixed
    AmiTool.switch_table_voice_logs
    
  end

  def sql_injection
    result = true

    if params[:cust_name]
      result = false

      if params[:cust_name].match(/^[[:alnum:]]+$/)
        result = true
      end
      
    end

    return result
  end
    
end
