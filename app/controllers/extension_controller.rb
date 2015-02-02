class ExtensionController < ApplicationController

  layout 'control_panel'
  
  before_filter :login_required
  before_filter :permission_require

  def index

		conditions = []

		sort_key = nil
		case params[:col]
		when /ext/
			 sort_key = 'extensions.number'              
		else
			 sort_key = 'extensions.number'
		end
      
    order = "#{sort_key} #{check_order_name(params[:sort])}" 

		if params.has_key?(:user) and not params[:user].empty?
			conditions << "login like '%#{params[:user]}%'"
		end
		if params.has_key?(:agent_id) and not params[:agent_id].empty?
			conditions << "cti_agent_id like '#{params[:agent_id]}%'"
		end

		unless conditions.empty?
			usrs = User.where(conditions.join(" and "))
			if usrs.empty?
				conditions = false
			else
				exts = ExtensionToAgentMap.where(:agent_id => usrs.map {|u| u.id}).group('agent_id').all
				if exts.empty?
					conditions = false
				else
					conditions = []
					exts_tmp = exts.map { |t| "'#{t.extension}'"}
					conditions << "extensions.number in (#{exts_tmp.join(',')})"
				end
			end
		end

		if conditions == false
			conditions = []
			conditions << "extensions.number is null"
		end
      
		if params.has_key?(:ext) and not params[:ext].strip.empty?
			conditions << "extensions.number like '%#{params[:ext].strip}%'"
		end
      
		if params.has_key?(:dids) and not params[:dids].strip.empty?
			conditions << "dids.number like '%#{params[:dids].strip}%'"
		end
      
    @extension = Extension.includes([:dids]).where(conditions.join(' and ')).order(order).group('extensions.number')
    @extension = @extension.paginate(:page => params[:page], :per_page => $PER_PAGE)
	  @page = params[:page] #nkm 27.02.2013
  
  end

  def edit

    begin
      @extension = Extension.where(:id => params[:id]).first
    rescue => e
      log("Edit","PhoneExtension",false,"id:#{params[:id]},#{e.message}")
      redirect_to :controller => 'extension',:action => 'index'
    end

  end

  def update
		
		begin
			
			@extension = Extension.where(:id => params[:id]).first
			if @extension.update_attributes(params[:extension]) and not @extension.number.blank?
				dids = params[:dids].to_s.strip
					unless dids.empty?
						Did.delete_all(:extension_id => @extension.id)
						dids = dids.split(",")
						dids.each do |did|
							did = did.strip
							next if did.empty?
							if Did.where(:number => did).first.nil?
								Did.new(:extension_id => @extension.id, :number => did).save
							end
						end
					else
						Did.delete_all(:extension_id => @extension.id)
					end
					
					ips = params[:ipadr].to_s.strip
					comp = params[:comp].to_s.strip
					cem = ComputerExtensionMap.where(:extension_id => @extension.id).first
					if not cem.nil? and ips.empty?
						ComputerExtensionMap.delete(cem)
					else
						if cem.nil?
							ComputerExtensionMap.new(:extension_id => @extension.id, :ip_address => ips,:computer_name => comp).save 
						else
							cem.update_attributes({:extension_id => @extension.id, :ip_address => ips,:computer_name => comp})
						end
					end
				 log("Update","PhoneExtension",true,"id:#{params[:id]},ext:#{@extension.number}")
			else
				 flash[:message] = "Update extension fail."
				 log("Update","PhoneExtension",false,"id:#{params[:id]}")
			end
		rescue => e
			 flash[:message] = "Update extension fail."
			 log("Update","PhoneExtension",false,"id:#{params[:id]},#{e.message}")
		end
		
		redirect_to :action => 'edit',:id => @extension.id
		
  end

  def new
		
    @extension = Extension.new
  
  end

  def create
    
    @extension = Extension.new(params[:extension])

    if @extension.save and not @extension.number.blank?
      
      dids = params[:dids].to_s.strip
      unless dids.empty?
        dids = dids.split(",")
        dids.each do |did|
          did = did.strip
          next if did.empty?
          if Did.where(:number => did).first.nil?
            Did.new(:extension_id => @extension.id, :number => did).save
          end
        end
      end
      
      ips = params[:ipadr].to_s.strip
      comp = params[:comp].to_s.strip
      unless ips.empty?
         ComputerExtensionMap.new(:extension_id => @extension.id, :ip_address => ips, :computer_name => comp).save 
      end
      
      log("Add","PhoneExtension",true,"ext:#{@extension.number}")
      redirect_to :controller => 'extension',:action => 'index'
    else
      log("Add","PhoneExtension",false,"ext:#{@extension.number}")
      flash[:message] = 'Extension number couldn\'t be null.'
      redirect_to :controller => 'extension',:action => 'new'
    end
    
  end

  def delete
    
    @extension = Extension.where(:id => params[:id]).first
    number = @extension.number
    
    if @extension.destroy()
      log("Delete","PhoneExtension",true,"ext:#{number}")
    else
       log("Delete","PhoneExtension",false,"ext:#{number}")
       flash[:message] = 'Delete Extension failed.'
    end
    
    redirect_to :action => 'index'
     
  end
  
  def watcher_result
    
    sql = ""
    
    day_ago = 0
    @pname = "Today"
    case params[:p]
    when '30days'
      day_ago = 30
      @pname = "30 Days ago"
    when '7days'
      day_ago = 7
      @pname = "30 Days ago"
    when '6months'
      day_ago = 180
    when 'alltime'
      day_ago = Aohs::LIMIT_SEARCH_DAYS
    else
      day_ago = 0
      params[:p] = 'today'
    end
    
    case params[:k]
    when 'unknown_comp'
      
      sql_a = "(select c.check_time,c.computer_name as comp2,c.remote_ip as ip2,c.login_name from current_computer_status c where date(check_time) >= (date(now()) - #{day_ago}) group by computer_name,remote_ip) a"
      sql_b = "(select e.number as extension,c.computer_name as comp1,c.ip_address as ip1 from extensions e left join computer_extension_maps c on e.id = c.extension_id) b"
      sql_c = "(select u.login as username,g.name as group_name from users u left join groups g on u.group_id = g.id) c"
      
      sql = "select * from #{sql_a} left join #{sql_b} on a.ip2 = b.ip1 left join #{sql_c} on a.login_name = c.username "
      sql << "where b.ip1 is null "
      sql << "group by a.comp2,a.ip2 "
      sql << "order by a.ip2"
    
    when 'unknown_user'

      sql_a = "(select e.number as extension,c.computer_name as comp1,c.ip_address as ip1 from extensions e left join computer_extension_maps c on e.id = c.extension_id) a"
      sql_b = "(select c.check_time,c.computer_name as comp2,c.remote_ip as ip2,c.login_name from current_computer_status c where date(check_time) >= (date(now()) - #{day_ago}) group by computer_name,remote_ip) b"
      sql_c = "(select u.login as username,g.name as group_name from users u left join groups g on u.group_id = g.id) c"
     
      sql = "select * from #{sql_a} left join #{sql_b} on a.ip1 = b.ip2 left join #{sql_c} on b.login_name = c.username "
      sql << "where c.username is null and b.ip2 is not null "
      sql << "group by a.extension,a.ip1 "
      sql << "order by c.username"
      
    when 'unmatched_user'
      
      #sql_a = "(select u.login as username,u.display_name,g.name as group_name,r.name as role_name from users u left join groups g on u.group_id = g.id left join roles r on u.role_id = r.id where u.flag = false and u.login not in (#{ Aohs::PRIVATE_ACCOUNTS.map { |a| "'#{a}'" } })) a"
      sql_a = "(select u.login as username,u.display_name,g.name as group_name,r.name as role_name from users u left join groups g on u.group_id = g.id left join roles r on u.role_id = r.id where u.flag = false ) a"
      sql_b = "(select c.check_time,c.computer_name as comp2,c.remote_ip as ip2,c.login_name from current_computer_status c where date(check_time) >= (date(now()) - #{day_ago}) group by computer_name,remote_ip) b"
      
      sql = "select * from #{sql_a} left join #{sql_b} on a.username = b.login_name "
      sql << "where b.login_name is null "
      sql << "order by a.group_name,a.username"
    
    when 'matched_success'
      
      sql_a = "(select e.number as extension,c.computer_name as comp1,c.ip_address as ip1 from extensions e left join computer_extension_maps c on e.id = c.extension_id) a"
      sql_b = "(select c.check_time,c.computer_name as comp2,c.remote_ip as ip2,c.login_name from current_computer_status c where date(check_time) >= (date(now()) - #{day_ago}) group by computer_name,remote_ip) b"
      sql_c = "(select u.login as username,u.id as agent_id1,g.name as group_name from users u left join groups g on u.group_id = g.id) c"
      sql_d = "(select v.agent_id as agent_id2 from #{VoiceLogTemp.table_name} v where date(v.start_time) >= (date(now()) - #{day_ago}) group by v.agent_id) d"
     
      sql = "select * from #{sql_a} left join #{sql_b} on a.ip1 = b.ip2 left join #{sql_c} on b.login_name = c.username left join #{sql_d} on c.agent_id1 = d.agent_id2 "
      sql << "where b.ip2 is not null and c.username is not null "
      sql << "group by a.extension,a.ip1 "
      sql << "order by a.extension,a.ip1 "
      
    else
      params[:k] = 'overview'
      
      sql_a = "(select e.number as extension,c.computer_name as comp1,c.ip_address as ip1 from extensions e left join computer_extension_maps c on e.id = c.extension_id) a"
      sql_b = "(select c.check_time,c.computer_name as comp2,c.remote_ip as ip2,c.login_name from current_computer_status c where date(check_time) >= (date(now()) - #{day_ago}) group by computer_name,remote_ip) b"
      sql_c = "(select u.login as username,u.id as agent_id1,g.name as group_name from users u left join groups g on u.group_id = g.id) c"
      sql_d = "(select v.agent_id as agent_id2 from #{VoiceLogTemp.table_name} v where date(v.start_time) >= (date(now()) - #{day_ago}) group by v.agent_id) d"
      
      sql = "select * from #{sql_a} left join #{sql_b} on a.ip1 = b.ip2 left join #{sql_c} on b.login_name = c.username left join #{sql_d} on c.agent_id1 = d.agent_id2 "
      sql << "group by a.extension,a.ip1 "
      sql << "order by a.extension,a.ip1 "
      
    end
    
    @logs = Extension.find_by_sql(sql)
  
  end
  
  def match_extension
		
		sql1 = ""
		sql1 << "select c.check_time,c.login_name,c.remote_ip,u.id as user_id "
		sql1 << "from current_computer_status c "
		sql1 << "join (select max(check_time) as lastest_check_time,login_name from current_computer_status group by login_name) c1 "
		sql1 << "on c.check_time = c1.lastest_check_time and c.login_name = c1.login_name "
		sql1 << "join users u on c.login_name = u.login "
		sql1 << "where (u.flag is null or u.flag = 0) "
		
		sql2 = ""
		sql2 << "select e.id,e.number,m.ip_address,m.computer_name from extensions e join computer_extension_maps m "
		sql2 << "on m.extension_id = e.id "
		
		sql = ""
		sql << "select a.*,b.number,e.agent_id from "
		sql << "(#{sql1}) a join (#{sql2}) b on a.remote_ip = b.ip_address "
		sql << "left join extension_to_agent_maps e "
		sql << "on b.number = e.extension "
		sql << "where (a.user_id <> e.agent_id or e.agent_id is null) "
    sql << "order by b.number "
    
		@result = Extension.find_by_sql(sql)
		
		if params[:perform_update] == "true"
			unless @result.empty?
				@result.each do |r|
					if r.user_id.to_i <= 0
						STDOUT.puts "Skip update ExtensionToAgentMap for #{r.number}, no user_id"
						next
					end
					if Time.parse(r.check_time) < Time.now
						STDOUT.puts "Skip update ExtensionToAgentMap for #{r.number}, no today's computer_log. logdate is #{Time.parse(r.check_time)}"
						next
					end
					eam = ExtensionToAgentMap.where(:extension => r.number).first
					if eam.nil?
						# no update found
						eam = ExtensionToAgentMap.new(:extension => r.number, :agent_id => r.user_id)
						eam.save!
						STDOUT.puts "Updated ExtensionToAgentMap for #{r.number}"
					elsif eam.agent_id.to_i != r.user_id.to_i
						# force to update
						if params[:force] == "yes"
							eam.agent_id = r.user_id
							eam.save!
							STDOUT.puts "Updated ExtensionToAgentMap for #{r.number}"
						else
							STDOUT.puts "Skip update ExtensionToAgentMap for #{r.number}, user_id <> agent_id"
						end
					else
						STDOUT.puts "Nothing to update ExtensionToAgentMap for #{r.number}"
					end
				end
			end
			redirect_to :action => 'match_extension'
		end
		
	end
  
end
