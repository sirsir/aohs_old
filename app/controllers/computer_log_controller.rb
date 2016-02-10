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
    
		conditions << "users.flag = 0"

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
      remote_ip = get_real_ip #request.remote_ip
    end

		event_name = ""
		if params.has_key?(:event) and not params[:event].empty?
			event_name = params[:event]
		end
		
    if not computer_name.nil? and not login_name.nil?
			
			data = {}
			data_versions = []
			params.each_pair do |key,val|
				key_name = key.to_s				
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
					# messages << "#{key_name} not match"
				end
				tmp << "#{key_name}=#{val}"
			end
			
			data[:versions]   = data_versions.join(',')
			data[:remote_ip]  = remote_ip
			data[:check_time] = Time.new.strftime("%Y-%m-%d %H:%M:%H")
      data[:computer_event] = event_name
      
      begin
        ccs = CurrentComputerStatus.where({ :remote_ip => remote_ip }).first
        if ccs.nil?
          ccs = CurrentComputerStatus.new(data)
          ccs.save!
        else
          ccs = CurrentComputerStatus.update_all(data,{:computer_name => computer_name, :remote_ip => remote_ip}) 
        end
      rescue => e
        STDERR.puts e.message
      end
      
      begin
        cpl = ComputerLog.new(data)
        cpl.save!
      rescue => e
        STDERR.puts e.message  
      end
    
      if messages.empty?
        messages << "OK"
      end
    else
      messages << "computer_name and windows_logon_name not set"
    end

    html = ""
    html << "computer_log_result="
    html << "computer_name=#{computer_name};"
    html << "windows_logon=#{login_name};"
    html << "parameters=#{tmp.join('|')};"
    html << "message=#{messages.join(',')};"
    
    if Aohs::COMPUTER_EXTENSION_LOOKUP
      r = update_computer_extension
      html << "computer_ext_result="
      html << r.join(";")
    end
    
    render :text => html, :layout => false
    
  end
  
  def update_computer_extension
    
    result = []
    
    computer_name = nil
    if params.has_key?(:computer_name) and not params[:computer_name].empty?
      computer_name = params[:computer_name].to_s.strip.gsub(" ","")
      result << "computer_name=#{computer_name}"
    end
      
    login_name = nil
    if params.has_key?(:login_name) and not params[:login_name].empty?
      login_name = params[:login_name].to_s.strip.gsub(" ","")
      result << "login=#{login_name}"
    end
    
    remote_ip = nil
    if params.has_key?(:remote_ip) and not params[:remote_ip].empty?
      login_name = params[:login_name].to_s.strip.gsub(" ","")
    else
      remote_ip = get_real_ip #request.remote_ip
    end
    result << "ip=#{remote_ip}"

		event_name = ""
		if params.has_key?(:event) and not params[:event].empty?
			event_name = params[:event]
		end
		
    if not computer_name.nil? and not remote_ip.nil? #and not event_name == "logoff"
      
			user   = nil
			ext    = nil      
      xconds = [
				{:computer_extension_maps => {:ip_address => remote_ip}},
				{:computer_extension_maps => {:computer_name => computer_name}}
			]
      
      while ext.nil? and not xconds.empty?
				cond = xconds.shift
				ext  = Extension.includes(:computer_extension_map).where(cond).first
			end
       
			unless ext.nil?
				
				user    = User.alive.where(:login => login_name).first
				user_id = (user.nil? ? 0 : user.id) 

				# update extension agent map
				eam = ExtensionToAgentMap.where({:extension => ext.number}).first
				if event_name == "logoff"
          unless eam.nil?
            eam.agent_id = 0
            eam.save
          end
        else
          if eam.nil?
            eam = ExtensionToAgentMap.new({:extension => ext.number, :agent_id => user_id})
          else
            eam.agent_id = user_id
          end
          eam.save!        
        end

				#unless eam.nil?
				#	dids = Did.where({ :extension_id => ext.id }).all
				#	unless dids.empty?
				#		dids.each do |did|
				#			dam = DidAgentMap.where({ :number => did.number }).first
				#			if dam.nil?
				#				dam = DidAgentMap.new({ :number => did.number, :agent_id => user_id })
				#			else
				#				dam.agent_id = user_id
				#			end
				#			dam.save!
				#		end						
				#	end
				#end

        result << "extension updated to #{user_id}|(#{ext.number})"
      
      else
        
        result << "extension not found."
				# clean up extension map if user not found
				# ExtensionToAgentMap.delete_all({:extension => ext.number})
				# dids = Did.where({ :extension_id => ext.id })
				# unless dids.empty?
				#	DidAgentMap.delete_all({:number => dids.map { |d| d.number }})
				# end
			end
			
    else			
      result << "no computer name or remote ip"
    end
    
    STDOUT.puts "ExtensionMapResult=#{result}"
    
    return result

  end

  def get_real_ip
    
    client_ip = request.env["HTTP_X_FORWARDED_FOR"].to_s
    if client_ip.empty?
      client_ip = request.env['REMOTE_ADDR'].to_s
      if client_ip.empty?
        client_ip = request.remote_ip
      end
    end
    
    return client_ip
  
 end

end
