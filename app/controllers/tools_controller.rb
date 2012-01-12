class ToolsController < ApplicationController
  
  include AmiTool

  layout "control_panel"

  before_filter :login_required
    
  def index

    @db_info = get_db_info
    @loggerid = get_active_logger_info
    
  end
  
end
