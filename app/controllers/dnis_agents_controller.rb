class DnisAgentsController < ApplicationController
  
  layout "control_panel"
  
  before_filter :login_required
  before_filter :permission_require, :except => [:sync]
  
  def index
    
    @dnis_agents = []
    
    if params[:page].to_i <= 0
      params[:page] = 1
    end
    @page = params[:page]
    
    conditions = []
    
    if params.has_key?(:dnis) and not params[:dnis].empty?
      conditions << "dnis like '#{params[:dnis]}%'"
    end  
    
    if params.has_key?(:ctilogin) and not params[:ctilogin].empty?
      conditions << "ctilogin = '#{params[:ctilogin]}'"
    end
    
    if params.has_key?(:team) and not params[:team].empty?
      conditions << "team like '#{params[:team]}%'"
    end
    
    order = ""
    case params[:col]
    when 'dnis'
      order = "dnis"
    when 'ctilogin'
      order = "ctilogin"
    when 'team'
      order = 'team'
    when 'cdate'
      order = 'created_at'
    when 'udate'
      order = 'updated_at'
    else
      order = 'dnis'
    end
    
    if params[:sort] == 'desc'
      params[:sort] = 'asc'
    elsif params[:sort] == 'asc'
      params[:sort] = 'desc'
    else
      params[:sort] = 'asc'
    end
    order = order + " " +params[:sort]
      
    @dnis_agents = DnisAgent.paginate(:page => params[:page],:per_page => $PER_PAGE,:conditions => conditions.join(' and '),:order => order)
          
  end
  
  def new
    
    @dnis_agent = DnisAgent.new
    
  end
  
  def create
    
    begin
      
      @dnis_agent = DnisAgent.new(params[:dnis_agent])
      if @dnis_agent.save
        
        log("Add","DnisAgent",true,"id=#{@dnis_agent.id}")
        flash[:notice] = 'Create dnis_agent has been successfully.'

        redirect_to :controller => 'dnis_agents',:action => 'index'  
              
      else
        
        log("Add","DnisAgent",false,@dnis_agent.errors.full_messages.compact)
        flash[:message] = @dnis_agent.errors.full_messages

        render :action => 'new'
        
      end
      
    rescue => e
      
      log("Add","DnisAgent",false,e.message)
      redirect_to :controller => 'dnis_agents',:action => 'index'      
      
    end
    
  end
  
  def edit
    
    @dnis_agent = DnisAgent.find(params[:id])
      
  end
  
  def update
    
    begin
      
      @dnis_agent = DnisAgent.find(params[:id])
      
      if @dnis_agent.update_attributes(params[:dnis_agent])
      
        log("Update","DnisAgent",true,"id=#{params[:id]}")
        flash[:notice] = 'Update dnis_agent has been successfully.'

        redirect_to :controller => 'dnis_agents',:action => 'index'  
              
      else
        
        log("Update","DnisAgent",false,@dnis_agent.errors.full_messages.compact)
        flash[:message] = @dnis_agent.errors.full_messages

        render :action => 'edit'
        
      end
        
    rescue => e
      
      log("Update","DnisAgent",false,e.message)
      redirect_to :controller => 'dnis_agents',:action => 'index' 
            
    end
      
  end
  
  def delete
    
    begin
      DnisAgent.delete_all({:id => params[:id]})
      log("Update","DnisAgent",true,"id=#{params[:id]}")
    rescue => e
      log("Delete","DnisAgent",false,e.message)
    end
    
    redirect_to :action => 'index'
    
  end
  
  def list
    
  end
  
  def sync
    
    result = true
    
    begin
      dau = DnisAgentUpdater.new
      result = dau.update
    rescue => e
      result = e.message
    end
    sleep(1)
    render :text => result, :layout => false
        
  end
  
end
