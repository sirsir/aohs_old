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

  

  def sql_injection0
    result = true

    if params[:cust_name]
      result = false
      p "falsssssss"

      if params[:cust_name].match(/^[[:alnum:]]+$/)
        p "true"
        result = true
      end  
    end

    if not result
      raise "sql_injection"
    end

  end

  def sql_injection

    params.each_pair { |k,v|
      unless [].include? k
        params[k] = v.gsub(/[^0-9a-z _\/]/i,"")
      end

    }

    

  end
    
end
