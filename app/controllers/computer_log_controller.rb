class ComputerLogController < ApplicationController
  
  layout "control_panel"
  
  skip_before_filter :verify_authenticity_token, :only => [:update]
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
    
	#edit 2013-11-21 add condition filter
	conditions << "users.flag=0"

    @page = (params[:page].to_i <= 1 ? 1 : params[:page].to_i)
     
    @comp_logs = CurrentComputerStatus.select("#{CurrentComputerStatus.table_name}.*,users.cti_agent_id").joins("left join users on users.login = #{CurrentComputerStatus.table_name}.login_name").where(conditions.join(' and ')).order(order)  
    @comp_logs = @comp_logs.paginate(:page => params[:page],:per_page => $PER_PAGE)

    @oss = CurrentComputerStatus.select('os_version as version').where("os_version is not null and os_version <> ''").group('os_version').order('os_version')
    @jvs = CurrentComputerStatus.select('java_version as version').where("java_version is not null and os_version <> ''").group('java_version').order('java_version')
    @aws = CurrentComputerStatus.select('watcher_version as version').where("watcher_version is not null and os_version <> ''").group('watcher_version').order('watcher_version')
    @avs = CurrentComputerStatus.select('audioviewer_version as version').where("audioviewer_version is not null and os_version <> ''").group('audioviewer_version').order('audioviewer_version')
    @ctis = CurrentComputerStatus.select('cti_version as version').where("cti_version is not null and os_version <> ''").group('cti_version').order('cti_version')
      
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
      
      ccs = CurrentComputerStatus.where({:computer_name => computer_name, :remote_ip => remote_ip}).first
      if ccs.nil?
        ccs = CurrentComputerStatus.new(data)
        ccs.save!
      else
        ccs = CurrentComputerStatus.update_all(data,{:computer_name => computer_name, :remote_ip => remote_ip})  
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
    
    if Aohs::COMPUTER_EXTENSION_LOOKUP
      r = update_computer_extension
      Aohs::COMP_RETRY_UPDATE.to_i.times do 
	r = update_computer_extension
      end
      html << "- computer extension --<br>"
      html << r.join("<br/>")
    end
    
    render :text => html, :layout => false
    
  end
  
  def update_computer_extension
    
    result = []
    
    computer_name = nil
    if params.has_key?(:computer_name) and not params[:computer_name].empty?
      computer_name = params[:computer_name].to_s.strip.gsub(" ","")
      result << "CompName=#{computer_name}"
    end
      
    login_name = nil
    if params.has_key?(:login_name) and not params[:login_name].empty?
      login_name = params[:login_name].to_s.strip.gsub(" ","")
      result << "Login=#{login_name}"
    end
    
    remote_ip = nil
    if params.has_key?(:remote_ip) and not params[:remote_ip].empty?
      login_name = params[:login_name].to_s.strip.gsub(" ","")
    else
      remote_ip = request.remote_ip
    end
    result << "IP=#{remote_ip}"

    if not computer_name.nil? and not remote_ip.nil?
        
        # get computer extension
        cond = []
        case Aohs::COMP_LOOKUP_BY_KEYS
        when :comp
          cond = {:computer_extension_maps => {:computer_name => computer_name}}
        when :ip
          cond = {:computer_extension_maps => {:ip_address => remote_ip}}
        when :comp_and_ip
          cond = ["computer_extension_maps.computer_name = ? and computer_extension_maps.ip_address = ?",computer_name,remote_ip]
        when :comp_or_ip
          cond = ["computer_extension_maps.computer_name = ? or computer_extension_maps.ip_address = ?",computer_name,remote_ip]
        end
        ext = Extension.includes(:computer_extension_map).where(cond).first
        unless ext.nil?
           user = User.alive.where(:login => login_name).first
           unless user.nil?

             # update extension agent map
             eam = ExtensionToAgentMap.where({:extension => ext.number}).first
             if eam.nil?
                eam = ExtensionToAgentMap.new({:extension => ext.number, :agent_id => user.id})  
                eam.save!
             else
                eam.update_attributes!({:extension => ext.number, :agent_id => user.id})  
             end
            
             # retry check
             eam = ExtensionToAgentMap.where({:extension => ext.number}).first
             if eam.nil?
                eam = ExtensionToAgentMap.new({:extension => ext.number, :agent_id => user.id})  
                eam.save!
             else
                eam.update_attributes!({:extension => ext.number, :agent_id => user.id})  
             end

             # update did agent map
             dids = Did.where({ :extension_id => ext.id })
             unless dids.empty?
                dids.each do |did|
                  dams = DidAgentMap.where({:number => did.number }).all
                  if dams.empty?
                     dam = DidAgentMap.new({:number => did.number , :agent_id => user.id})
                     dam.save
                  else
                     dams.update_all({:agent_id => user.id},{:number => did.number })
                  end
                end
             end
             
             result << "Update extension successfully #{user.login}(#{ext.number})"
           else
             
             result << "User not found, deleted extension map for #{ext.number}"

             # clean up extension map if user not found
             ExtensionToAgentMap.delete_all({:extension => ext.number})
             dids = Did.where({ :extension_id => ext.id })
             unless dids.empty?
                DidAgentMap.delete_all({:number => dids.map { |d| d.number }})
             end

           end
        else
	  result << "Extension not found by #{Aohs::COMP_LOOKUP_BY_KEYS}"
        end
    else
      result << "Computer or IP not defined"
    end
    
    return result

  end
  
end
