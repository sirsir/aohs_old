class ApplicationController < ActionController::Base
  
  protect_from_forgery
  
  include AuthenticatedSystem
  include AmiPermission
  include AmiLog
  include Format

  before_filter :initial_config
  before_filter :valid_sql_injection
  
  def initial_config
    
    $CF = AmiConfig::UserConf.new(session[:user_id])
    $PER_PAGE = $CF.get('client.aohs_web.number_of_display_list').to_i
    $SERVER_ROOT_URL = Aohs::SITE_ROOT
    
    ## fixed
    AmiTool.switch_table_voice_logs
    
  end

  def valid_sql_injection
    if ['voice_logs','customer','customers'].include?(controller_name.to_s)
      params.each do |kname,val|
        next if ['controller','action'].include?(kname)
        next if val.blank?

        # perform check
        if found_sql_injection?(val)
          render :status => 500
        end
      end
    end
  end
  
  def found_sql_injection?(val)
    txt = val.to_s.chomp.strip

    regexp = /\b(OR|AND|ALTER|CREATE|DELETE|DROP|EXEC(UTE){0,1}|INSERT( +INTO){0,1}|MERGE|SELECT|UPDATE|UNION( +ALL){0,1})\b/i

    if txt.match(regexp)
      return true
    end

    return false
  end
    
end
