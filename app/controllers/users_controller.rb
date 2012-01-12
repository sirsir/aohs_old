class UsersController < ApplicationController

  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  skip_before_filter :verify_authenticity_token, :only => [:update_agent_activity, :update_extension]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :login_required , :only => [:profile]

  CTI_STATUS_LOGOUT = "logout"
  
  def profile
    
    $LAYOUT = "application"
    
    render :layout => 'application'

  end  

  def change_password
    result = []
    begin
     @user = User.alive.where({:id => params[:id]}).first
    if @user.authenticated?(params[:opw])
       if @user.reset_password(params[:npw])
          if @user.save!
             log("Update","User",true,"change user's password")
             result << "t"
             result << "change password complete"
          end
       else
          log("Update","User",false,"change user's password")
          result << "f"
          result << "you password less than minimum require."
       end
    else
      result << "f"
      result << "your password are wrong. please type a correct password."
      log("Update","User",false)
    end
      render :text => result.join(",")
    rescue => ex
       log("Update","User",false,"id:#{@user.id}, name:#{@user.login}, msg:#{ex.message}")
       result << "f"
       result << ex.message
       render :text => result.join(",")
    end
  end
   
  def change_type
    
    user_id = params[:id]
    change_from = params[:type].to_sym
    result = true
      
    user = User.where({:id => user_id }).first
    
    target = ""      
    case change_from
    when :managers
      target = "agents"
      
      # remove group_member
      rs = GroupMember.where({ :user_id => user.id })
      unless rs.empty?
        GroupMember.delete_all({ :user_id => user.id })
      end
        
      # remove group_manager
      rs = GroupManager.where({ :user_id => user.id })
      unless rs.empty?
        GroupManager.delete_all({ :user_id => user.id })
      end
         
      # remove leader from groups
      rs = Group.where({:leader_id => user.id })
      unless rs.empty?
        rs.each do |group|
          group.update_attributes({:leader_id => nil })
        end
      end
              
      # change group from user
      group = Group.where({:id => params[:group_id].to_i }).first
      unless group.nil?
        group = group.id
      else
        group = nil
      end
      user.update_attributes({:group_id => group})
        
      # change role
      role_id = Role.where({:name => 'Agent'}).first.id rescue 0
      user.update_attributes({:role_id => role_id})

      # change_type
      ActiveRecord::Base.connection.execute("UPDATE users set type = 'Agent' WHERE id = #{user.id}")      
                        
    when :agents
      target = "managers"
 
      # change role
      role_id = Role.where({:name => params[:role]}).first.id rescue 0
      user.update_attributes({:role_id => role_id})
      
      # remove group  
      user.update_attributes({:group_id => nil})

      # change type
      ActiveRecord::Base.connection.execute("UPDATE users set type = 'Manager' WHERE id = #{user.id}")
    
    else
      
      target = change_from.to_s  
      result = false
      
    end
    
    log("Update","User",result,"id:#{user.id}, name:#{user.login}, change role to #{target}")
    
    redirect_to :controller => target, :action => 'edit', :id => user.id
    
  end
  #
  # watcher send information for map extension.
  #

  def update_extension

    messages = []

    username = nil
    if params.has_key?(:username) and not params[:username].empty?
      username = params[:username]
    end
    
    ctilogin = nil
    if params.has_key?(:ctilogin) and not params[:ctilogin].empty?
      ctilogin = params[:ctilogin]
    end
	if not Aohs::CTI_LOGOUT_ENABLE
		ctilogin = "login"
	end
	
    remote_ip = nil
    if params.has_key?(:remote_ip) and not params[:remote_ip].empty?
      remote_ip = params[:remote_ip]
    else
      remote_ip = request.remote_ip
    end
	
	ctistatus = nil
	
    if params.has_key?(:ctistatus) and not params[:ctistatus].empty?
	  # val = login,logout
      ctistatus = params[:ctistatus]
    end
    
    ext_numbers = []
    if params.has_key?(:extension) and not params[:extension].empty?
      ext_numbers = params[:extension].to_s.split(',')
      unless ext_numbers.empty?
        ext_numbers = ext_numbers.sort
      end
    end

    #
    # get agent.id
    #
    
    begin

      agent_id = 0
      agent_login = nil
      if Aohs::CTI_EXTENSION_LOOKUP
        if((not ctilogin.nil? or not username.nil?) and not ext_numbers.empty?)
  
          # - find with ctiloggin-agent_id
          if not ctilogin.nil? and Aohs::CTI_LOOKUP_BY_CTIID 
            usrs = User.alive.where({:cti_agent_id => ctilogin}).order('created_at desc').all
            unless usrs.empty?
              messges << "found users.ctilogin more than one record." if usrs.length > 1
              agent_id = usrs.first.id
              agent_login = usrs.first.login
            else
              messages << "ctilogin not found"
            end
          end
          if not username.nil? and agent_id == 0 and Aohs::CTI_LOOKUP_BY_USERN
            usrs = User.alive.where({:login => username}).order('created_at desc')
            unless usrs.empty?
              agent_id = usrs.first.id
              agent_login = usrs.first.login
            else
              messages << "window account not found"
            end
          end
 
          # if nil add new user
          if agent_id <= 0 and Aohs::AUTO_CRTNEW_USR
            n_login = "#{Aohs::DEFAULF_USERN_PATTERN}#{ctilogin}"
            usr = Agent.create({
              :login => n_login,
              :display_name => n_login,
              :role_id => Role.where({:name => 'Agent'}).first.id,
              :group_id => 0,
              :password => Aohs::DEFAULT_PASSWORD_NEW,
              :password_confirmation => Aohs::DEFAULT_PASSWORD_NEW,
              :cti_agent_id => ctilogin,
              :state => 'active'
            })
            if usr.save
              agent_id = usr.id
              agent_login = usr.login
            else
              agent_id = 0
              messages << "create user failed because #{usr.errors.full_messages}"
            end
            messages << "create tmp user #{n_login}:#{agent_id}"
          end
  
          if agent_id > 0
  
              #
              # mapping agent
              #
              
              unless ext_numbers.empty?
                ext_numbers.each do |ext|
                  
				  # add extension
				  if true
					if ext =~ /^1/
						old_ext = Extension.where({:number => ext}).first
						if old_ext.nil?
							new_ext = Extension.new({:number => ext})
							new_ext.save
						end
					end
				  end
				  
                  # mapping extension
                  eams = ExtensionToAgentMap.where({ :extension => ext })
                  begin
					if ctistatus == CTI_STATUS_LOGOUT
						unless eams.empty?
							ExtensionToAgentMap.delete(eams)
							messages << "remove mapping extension"
						end
					else
						unless eams.empty?
						  eam = ExtensionToAgentMap.update_all({:agent_id => agent_id, :extension => ext },{:extension => ext})
						else
						  eam = ExtensionToAgentMap.new({ :agent_id => agent_id, :extension => ext })
						  eam.save!
						end					
					end
                  rescue => e
                    messages << "update mapping extension error cause #{e.message}"
                  end
                  # mapping dids
                  ext_tmp = Extension.where({:number => ext}).first
                  unless ext_tmp.nil?
                    unless ext_tmp.dids.empty?
                      ext_tmp.dids.each do |did|
                        dams = DidAgentMap.where({ :number => did }).all
                        if dams.empty?
                          dam = DidAgentMap.new({:agent_id => agent_id, :number => did })
                          dam.save!
                        else
                          dam = DidAgentMap.update_all({:agent_id => agent_id},{:number => did})
                        end  
						if ctistatus == CTI_STATUS_LOGOUT
							DidAgentMap.delete(dam)
						end
                      end
                    else
                      messages << "did of '#{ext}' not found in master."
                    end
                  else
                    messages << "extension '#{ext}' not found in master." 
                  end
                  
                end
              end
  
              #
              # watcher log
              #
  
              cws_data = {
                  :check_time => Time.new.strftime("%Y-%m-%d %H:%M:%S"),
                  :agent_id => agent_id,
                  :extension => ext_numbers.first,
                  :extension2 => ext_numbers.last,
                  :login_name => username,
                  :remote_ip => remote_ip,
				  :ctistatus => ctistatus
              }
  
              wl = WatcherLog.new(cws_data)
              wl.save!
  
              cws = CurrentWatcherStatus.where({:login_name => username, :remote_ip => remote_ip }).first
              if cws.nil?
                cws = CurrentWatcherStatus.new(cws_data)
                cws.save!
              else
                cws.update_attributes(cws_data)
              end
  
              if messages.empty?
                messages << "OK"
              end
  
          else
            messages << "agent_id is not defined"
          end
  
        else
          messages << "username or agent_id or ext are not defined"
        end
      else
        messages << "cti extension mapping was stopped" 
      end
    rescue => e
      messages << e.message
    end

    html = ""
    html << "- update_extension result -<br/>"
    html << "agent_id=#{agent_id}<br/>"
    html << "agent_name=#{agent_login}<br/>"
    html << "username=#{username}<br/>"
    html << "remote_ip=#{remote_ip}<br/>"
    html << "extensions=#{ext_numbers.join(',')}<br/>"
    html << "message=#{messages.join(', ')}</br>"
    html << "time=#{Time.new.to_s}"

    render :text => html, :layout => false

  end

  #
  # update_agent_activity from watcher
  #

  def update_agent_activity

    messages = []
    split_key = "\t"
    split_line = "\n"

    # read informations
    
    data_sources = ""
    if params.has_key?(:result) and not params[:result].empty?
      data_sources = params[:result].gsub(/^result=/,"")
    end
    
    data_sources = data_sources.split(split_line)

    login_name = nil
    mac_address = nil

    activities = []
    idles = []
    access_logs = []
    
    unless data_sources.empty?
      read_type = nil
      STDOUT.puts "Read activity result.."
      data_sources.each do |line|

        next if line.nil?

        line = line.strip
        next if line.empty?

        case line
        when /^#/
          read_type = :property
        when /^__AGENT_ACTIVITY__/,/^__FOREGROUND_CHECKER__/
          read_type = :activity
          next
        when /^__IDLE_TIME__/
          read_type = :idle
          next
        when /^__ACCESSLOG__/,/__BROWSERHISTORY__/
          read_type = :access_log
          next
        end

        case read_type
        when :property
          case line
          when /^#LoginName=/
            login_name = line.gsub(/^#LoginName=/,"")
          when /^#MacAddress=/
            mac_address = line.gsub(/^#MacAddress=/,"")
          end
        when :activity
          start_time, duration, pname, wtitle  = line.split(split_key)
          activities << {:start_time => start_time, :duration => duration.to_i, :process_name => pname, :window_title => wtitle}
        when :idle
          start_time, duration = line.split(split_key)
          idles << {:start_time => start_time, :duration => duration.to_i}
        when :access_log
          url, count, access_time = line.split(split_key)
          access_logs << {:access_time => access_time, :count => count.to_i, :url => url}
        end
      end
    end

    STDOUT.puts "ACTV = #{login_name} -- #{mac_address}"

    if not login_name.nil? and not mac_address.nil?

      result_recs = UserActivityLog.update_agent_activities(login_name,mac_address,request.remote_ip, activities)
      if result_recs > 0
        messages << "#{result_recs}/#{activities.length} update activities success"
        result_recs = 0
      else
        messages << "no activities to update or failed"
      end

      result_recs = UserIdleLog.update_user_idles(login_name,mac_address,request.remote_ip,idles)
      if result_recs > 0
        messages << "#{result_recs}/#{idles.length} update idles success"
        result_recs = 0
      else
        messages << "no idles to update or failed"
      end

      result_recs = AccessLog.update_access_logs(login_name,mac_address,request.remote_ip,access_logs)
      if result_recs > 0
        messages << "#{result_recs}/#{access_logs.length} update access log success"
        result_recs = 0
      else
        messages << "no access log to update or failed"
      end

    else
      messages << "no logon name or mac address"
    end

    html = ""
    html << "- update user activities -<br/>"
    html << "message=#{messages.join(', ')}"

    #STDOUT.puts "HTML>>#{html}"

    render :text => html, :layout => false

  end
  
  def new

  end
  
  def create

  end

  def suspend
    @user.suspend! 
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

  protected

  def find_user
    @user = User.find(params[:id])
  end

end
