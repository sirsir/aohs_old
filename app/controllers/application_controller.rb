
class ApplicationController < ActionController::Base

  before_filter :initial_config
  helper :all

  # restful_authentication
  
  $LOAD_PATH << 'vendor/plugins/acts_as_state_machine/lib'
  require 'acts_as_state_machine'
 
  # acts_as_taggable
  
  $LOAD_PATH << 'mbleigh-acts-as-taggable-on-1.0.5'
  require 'acts-as-taggable-on'

  include AuthenticatedSystem
  include AmiPermission
  include AmiLog
  include Format

  DAYS_OF_THE_WEEK = %w[mo tu we th fr sa su]
  CALL_DIRECTION_COLORS = { :i => '#00CC00', :o => '#316AC5', :e => '#0066CC', :u => '#993399' }
  CALL_EVENTS = {:transfer => 'Transfer', :hold => 'Hold'}

  def initial_config
    
    begin
      AmiConfig.set_user(session[:user_id]) 
    rescue => e
      STDERR.puts "[AppController] - Cannot set user id"
    end
    
    $PER_PAGE = AmiConfig.get('client.aohs_web.number_of_display_list').to_i
    $AUDIO_BASE_URL = AmiConfig.get('client.aohs_web.audioBaseUrl').to_s
    $SERVER_ROOT_URL = AmiConfig.get('client.aohs_web.serverRootUrl').to_s
    $FILTER_SHOW_ENA = AmiConfig.get('client.aohs_web.alwayShowFilterWhenSearch')
    
  end
  
end