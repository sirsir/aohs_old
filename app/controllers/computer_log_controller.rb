class ComputerLogController < ApplicationController
  
  layout "control_panel"
  
  before_filter :login_required, :except => [:update]
  before_filter :permission_require, :except => [:update]
      
  def index
    
    conditions = []
    if params.has_key?(:cname) and not params[:cname].empty?
      conditions << "computer_name like '#{params[:cname]}%'"
    end
    if params.has_key?(:lname) and not params[:lname].empty?
      conditions << "login_name like '#{params[:lname]}%'"
    end    
    if params.has_key?(:os) and not params[:os].empty?
      conditions << "os_version like '#{params[:os]}'"
    end
    if params.has_key?(:jv) and not params[:jv].empty?
      conditions << "java_version like '#{params[:jv]}'"
    end        
    if params.has_key?(:aw) and not params[:aw].empty?
      conditions << "watcher_version like '#{params[:aw]}'"
    end    
    if params.has_key?(:av) and not params[:av].empty?
      conditions << "audioviewer_version like '#{params[:av]}'"
    end
    if params.has_key?(:cti) and not params[:cti].empty?
      conditions << "cti_version like '#{params[:cti]}'"
    end
    if params.has_key?(:ip) and not params[:ip].empty?
      conditions << "remote_ip like '#{params[:ip]}%'"
    end
    if params.has_key?(:agid) and not params[:agid].empty?
      conditions << "users.cti_agent_id = '#{params[:agid]}'"
    end
    
    order = "computer_name"
    case params[:col]
    when 'comp_name'
      order = "computer_name"
    when 'login'
      order = "login_name"
    when 'os'      
      order = "os_version"
    when 'jv'
      order = "java_version"
    when 'aw'
      order = "watcher_version"
    when 'av'
      order = "audioviewer_version"
    when 'cti'
      order = "cti_version"
    when 'ip'
      order = "remote_ip"
    when 'agid'
      order = "users.cti_agent_id"
    when 'upd'
      order = "check_time"	
    end
	  
    order = "#{order} #{check_order_name(params[:sort])}" 
    
    @page = (params[:page].to_i <= 1 ? 1 : params[:page].to_i)
      
    @comp_logs = CurrentComputerStatus.paginate(
        :select => "#{CurrentComputerStatus.table_name}.*,users.cti_agent_id",
        :page => params[:page],
        :per_page => $PER_PAGE,
			  :joins => "left join users on users.login = #{CurrentComputerStatus.table_name}.login_name",
        :conditions => conditions.join(' and '),
        :order => order)

    @oss = CurrentComputerStatus.find(:all,:select => 'os_version as version',:conditions => "os_version is not null and os_version <> ''", :group => 'os_version',:order => 'os_version')
    @jvs = CurrentComputerStatus.find(:all,:select => 'java_version as version',:conditions => "java_version is not null and os_version <> ''",:group => 'java_version',:order => 'java_version')
    @aws = CurrentComputerStatus.find(:all,:select => 'watcher_version as version',:conditions => "watcher_version is not null and os_version <> ''",:group => 'watcher_version',:order => 'watcher_version')
    @avs = CurrentComputerStatus.find(:all,:select => 'audioviewer_version as version',:conditions => "audioviewer_version is not null and os_version <> ''",:group => 'audioviewer_version',:order => 'audioviewer_version')
    @ctis = CurrentComputerStatus.find(:all,:select => 'cti_version as version',:conditions => "cti_version is not null and os_version <> ''",:group => 'cti_version',:order => 'cti_version')
      
  end
  
  def update
    
    messages = []
    tmp = []
      
    computer_name = nil
    if params.has_key?(:computer_name) and not params[:computer_name].empty?
      computer_name = params[:computer_name]
    end
      
    login_name = nil
    if params.has_key?(:login_name) and not params[:login_name].empty?
      login_name = params[:login_name]
    end
    
    remote_ip = nil
    if params.has_key?(:remote_ip) and not params[:remote_ip].empty?
      remote_ip = params[:remote_ip]
    else
      remote_ip = request.remote_ip
    end
    
    if not computer_name.nil? and not login_name.nil?
      if params
        data = {}
        data_versions = []
        params.each_pair do |key,val|
          key_name = key.to_s
          next if ['controller','action','id'].include?(key_name)
          
          case key_name
          when /^computer_name$/
            data[:computer_name] = val
          when /^login_name$/
            data[:login_name] = val          
          when /^watcher/
            data[:watcher_version] = val
          when /^advw/,/^audioviewer/
            data[:audioviewer_version] = val
          when /^cti/
            data[:cti_version] = val
          when /^os/
            data[:os_version] = val
          when /^java/
            data[:java_version] = val
          when /(.+)_version$/
            data_versions << "#{key_name}=#{val}"
          else
            messages << "#{key_name} not match"
          end
          
          tmp << "#{key_name}=#{val}"
        end
        
        data[:versions] = data_versions.join(',')
        data[:remote_ip] = remote_ip
        data[:check_time] = Time.new.strftime("%Y-%m-%d %H:%M:%H")
      end
      
      ccs = CurrentComputerStatus.find(:first,:conditions => {:computer_name => computer_name, :login_name => login_name})
      if ccs.nil?
        ccs = CurrentComputerStatus.new(data)
        ccs.save!
      else
        ccs = CurrentComputerStatus.update_all(data,{:computer_name => computer_name, :login_name => login_name})  
      end
        
      cpl = ComputerLog.new(data)
      cpl.save!
           
      if messages.empty?
        messages << "OK"
      end
    else
      messages << "computer_name and windows_logon_name not set"
    end

    html = ""
    html << "- computer log -<br/>"
    html << "computer_name=#{computer_name}<br/>"
    html << "windows_logon=#{login_name}<br/>"
    html << "parameters=#{tmp.join('|')}<br/>"
    html << "message=#{messages.join(',')}"
    
    render :text => html, :layout => false
    
  end
  
end
