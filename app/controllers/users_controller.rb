class UsersController < ApplicationController

   layout "control_panel"

   before_filter :login_required , :only => [:profile]

  def index
     @users = User.paginate(:page => params[:page], :per_page => 26, :order => 'id', :conditions =>["type=:type", params])
     respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @users }
     end
  end

  def profile
    
    $LAYOUT = "application"
    
    render :layout => 'application'

  end

  def change_password
    result = []
    begin
     @user = User.find(params[:id])
    if @user.authenticated?(params[:opw])
       if @user.reset_password(params[:npw])
          if @user.save!
             log("Update","User",true)
             result << "t"
             result << "change password complete"
          end
       else
          log("Update","User",false)
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
       log("Update","User",false,"ID:#{@user.id},#{ex.message}")
       result << "f"
       result << ex.message
       render :text => result.join(",")
    end
  end
   
  def change_type
    
    user_id = params[:id]
    change_from = params[:type].to_sym
    result = true
      
    user = User.find(:first,:conditions => { :id => user_id })
    
    target = ""      
    case change_from
    when :managers
      target = "agents"
      
      # remove group_member
      rs = GroupMember.find(:all,:conditions => { :user_id => user.id })
      unless rs.empty?
        GroupMember.delete_all({ :user_id => user.id })
      end
        
      # remove group_manager
      rs = GroupManager.find(:all,:conditions => { :user_id => user.id })
      unless rs.empty?
        GroupManager.delete_all({ :user_id => user.id })
      end
         
      # remove leader from groups
      rs = Group.find(:all,:conditions => {:leader_id => user.id })
      unless rs.empty?
        rs.each do |group|
          group.update_attributes({:leader_id => nil })
        end
      end
              
      # change group from user
      group = Group.find(:first,:conditions => {:id => params[:group_id].to_i })
      unless group.nil?
        group = group.id
      else
        group = nil
      end
      user.update_attributes({:group_id => group})
        
      # change role
      role_id = Role.find(:first,:conditions => {:name => 'Agent'}).id rescue 0
      user.update_attributes({:role_id => role_id})

      # change_type
      ActiveRecord::Base.connection.execute("UPDATE users set type = 'Agent' WHERE id = #{user.id}")      
                        
    when :agents
      target = "managers"
 
      # change role
      role_id = Role.find(:first,:conditions => {:name => params[:role]}).id rescue 0
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

    #
    # recive params
    #

    username = nil
    if params.has_key?(:username) and not params[:username].empty?
      username = params[:username]
    end

    ctilogin = nil
    if params.has_key?(:ctilogin) and not params[:ctilogin].empty?
      ctilogin = params[:ctilogin]
    end

    remote_ip = nil
    if params.has_key?(:remote_ip) and not params[:remote_ip].empty?
      remote_ip = params[:remote_ip]
    else
      remote_ip = request.remote_ip
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

      if((not ctilogin.nil? or not username.nil?) and not ext_numbers.empty?)

        # - find with ctiloggin-agent_id
        if not ctilogin.nil?
          usrs = User.find(:all,:conditions => {:cti_agent_id => ctilogin},:order => 'created_at desc')
          unless usrs.empty?
            if usrs.length > 1
              messges << "found users.ctilogin more than one record."
            end
            agent_id = usrs.first.id
            agent_login = usrs.first.login
          else
            messages << "ctilogin not found"
          end
        end

        if not username.nil? and agent_id == 0
          usrs = User.find(:all,:conditions => {:login => username},:order => 'created_at desc')
          unless usrs.empty?
            agent_id = usrs.first.id
            agent_login = usrs.first.login
          else
            messages << "window account not found"
          end
        end

        # if nil add new user
        if agent_id <= 0
          n_login = "newUser#{ctilogin}"
          usr = Agent.create({
            :login => n_login,
            :display_name => n_login,
            :role_id => 0,
            :group_id => 0,
            :password => "aohsweb",
            :password_confirmation => "aohsweb",
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
            # mapping agent <users.id> and extension <extension_number>
            #
            unless ext_numbers.empty?
              ext_numbers.each do |ext|
                eams = ExtensionToAgentMap.find(:all,:conditions => { :extension => ext })
                unless eams.empty?
                  eam = ExtensionToAgentMap.update_all({:agent_id => agent_id, :extension => ext },{:extension => ext})
                else
                  eam = ExtensionToAgentMap.create({
                    :agent_id => agent_id,
                    :extension => ext
                  })
                end
              end
            end

            #
            # mapping agent and dids from extension number
            #
            unless ext_numbers.empty?
              ext_numbers.each do |ext_number|
                ext_tmp = Extension.find(:first,:conditions => { :number => ext_number })
                unless ext_tmp.nil?
                  dids = ext_tmp.dids
                  unless dids.empty?
                    dids = dids.map { |d| d.number }
                    dids.each do |did|
                      dams = DidAgentMap.find(:all,:conditions => { :number => did })
                      if dams.empty?
                        dam = DidAgentMap.create({:agent_id => agent_id, :number => did })
                      else
                        dam = DidAgentMap.update_all({:agent_id => agent_id},{:number => did})
                      end
                    end
                  else
                    messages << "did of '#{ext_number}' not found."
                  end
                else
                  messages << "extension '#{ext_number}' not found."
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
                :remote_ip => remote_ip
            }

            wl = WatcherLog.new(cws_data)
            wl.save!

            cws = CurrentWatcherStatus.find(:first,:conditions => {:login_name => username, :remote_ip => remote_ip })
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

    data_sources = params[:result].gsub(/^result=/,"")

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

      result_recs = UserActivity.update_agent_activities(login_name,mac_address,request.remote_ip, activities)
      if result_recs > 0
        messages << "#{result_recs}/#{activities.length} update activities success"
        result_recs = 0
      else
        messages << "no activities to update or failed"
      end

      result_recs = UserIdle.update_user_idles(login_name,mac_address,request.remote_ip,idles)
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

end

