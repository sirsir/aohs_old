class ToolsController < ApplicationController
  
  include AmiTool

  layout "control_panel"

  before_filter :login_required
    
  def index

    @db_info = get_db_info
    @loggerid = get_active_logger_info
    
    @hostname = request.env["SERVER_ADDR"]
    
    @jscheds = JobScheduler.order(:name).all
    
    @mysqli = AmiTool.get_mysql_info
    
    @tablesi = (Aohs::MOD_CALL_BROWSER ? AmiTool.get_tables_info : [])
    
    @webpublic = AmiTool.public_website?
    
  end
  
  def update
  
    case params[:name].to_sym
      when :sched
        js_id = params[:id]
        js_state = params[:state]
        js = JobScheduler.where(:id => js_id).first
        AmiScheduler.jstart_stop_job(js.name,js_state)
      when :webs
        data = ((params[:run] == "false") ? false : true)
        AmiTool.public_website?(data)
    end
  
    redirect_to :action => 'index'
    
  end
  
end
