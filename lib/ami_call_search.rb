module AmiCallSearch
 
  def set_current_user_for_call_search(user_id=nil)

    @app_user = nil
		if (not user_id.nil?) and (user_id.to_i > 0)
			user_id = current_user.id
		end
    @app_user = User.where({:id => user_id }).first
    
  end
  
  def retrive_sort_columns(sort_by,order_by="DESC")

    orders 		= []
		order_sql = ""
		order_by  = "DESC" if order_by.empty?
		
    vl_cols 		= VoiceLogTemp.new.attribute_names.to_a
    vc_cols 		= VoiceLogCounter.new.attribute_names.to_a
    vl_tblname  = VoiceLogTemp.table_name
    
    case true
		when vl_cols.include?(sort_by)
			order_sql = "#{vl_tblname}.#{sort_by}"
    when ['agent'].include?(sort_by),['agent_name'].include?(sort_by)
      order_sql = "users.login"        
    when ['customer'].include?(sort_by)
      order_sql = "customers.name"
    when vc_cols.include?(sort_by)
      order_sql = "voice_log_counters.#{sort_by}"
		else
			order_sql = "#{vl_tblname}.start_time"
    end
		order_sql << " #{order_by}"
    orders 		<< order_sql
    
    return orders
    
  end

  def retrive_datetime_condition(period_type,st_date,st_time,ed_date,ed_time)

    dt_cond 				= nil
    vl_tbl_name 		= VoiceLogTemp.table_name
    now 						= Date.today    
    call_from_date  = now
    call_to_date    = now
    oldest_call_date = 2.year.ago
    period_type 		= period_type.to_i unless period_type.blank?

		case period_type
		when 1
			#today
		when 2
			#yesterday
			yesterday 			= now - 1
			call_from_date 	= yesterday
			call_to_date   	= yesterday
		when 3
			#this week
			call_from_date 	= now.beginning_of_week
		when 4
			#last week
			last_week 			= (now.beginning_of_week - 1)
			call_from_date 	= last_week.beginning_of_week
			call_to_date   	= last_week.end_of_week
		when 5
			#this month
			call_from_date 	= now.beginning_of_month
		when 6
			#last month
			last_month 			= (now.beginning_of_month - 1)
			call_from_date 	= last_month.beginning_of_month
			call_to_date   	= last_month.end_of_month
		when 7
			#this year
			call_from_date 	= now.beginning_of_year
		when 8
			#all => Search all
			call_from_date 	= oldest_call_date
		when 9
			# one month ago
			month_later 		= now - 30
			call_from_date 	= month_later
		when 10
			# six month ago
			six_month_later = now - (6 * 30)
			call_from_date 	= six_month_later
		when 11
			# one week ago
			call_from_date 	= now - 7
		when 0
			#custom ...
			stdate, sttime, eddate, edtime = nil, "00:00:00", nil, "23:59:59"
			
			if (not st_time.nil?) and (not st_time.empty?) and st_time.to_s =~ /(\d\d):(\d\d)/
				sttime = Time.parse(st_time).strftime("%H:%M:00")
			end     
			if (not st_date.nil?) and (not st_date.empty?)
				stdate = Date.parse(st_date).strftime("%Y-%m-%d")
				stdate << " #{sttime}"
				call_from_date = stdate
			end
			
			if (not ed_time.nil?) and (not ed_time.empty?) and ed_time =~ /(\d\d):(\d\d)/
				edtime = Time.parse(ed_time).strftime("%H:%M:59")
			end
			if (not ed_date.nil?) and (not ed_date.empty?)
				eddate = Date.parse(ed_date).strftime("%Y-%m-%d")
				eddate << " #{edtime}"
				call_to_date = eddate
			end
			call_from_date = "#{min_date.strftime("%Y-%m-%d")} 00:00:00" if stdate.nil?
			call_to_date = "#{now.strftime("%Y-%m-%d")} 23:59:59" if eddate.nil?
		end
    
    if period_type == 0
      # custom period
      dt_cond = "#{vl_tbl_name}.start_time BETWEEN '#{call_from_date}' AND '#{call_to_date}'"
    else
      dt_cond = "#{vl_tbl_name}.start_time BETWEEN '#{call_from_date.strftime("%Y-%m-%d")} 00:00:00' AND '#{call_to_date.strftime("%Y-%m-%d")} 23:59:59'"
    end

    return dt_cond
  
  end

  def retrive_duration_conditions(from_dur,to_dur)

    vl_tbl_name = VoiceLogTemp.table_name
    dur_cond 		= nil
    stdu 				= nil
    eddu 				= nil
    
    if not from_dur.to_s.strip.empty?
      if (from_dur.to_s.strip =~ /^([0-9]+):([0-9]+)$/) != nil
        d = from_dur.split(':')
        stdu = (d.first.to_i * 60) + d.last.to_i
      else
        stdu = (from_dur.to_i * 60)
      end
    end
		
    if not to_dur.to_s.strip.blank?
      if (to_dur.to_s.strip =~ /^([0-9]+):([0-9]+)$/) != nil
        d = to_dur.split(':')
        eddu = (d.first.to_i * 60) + d.last.to_i
      else
        eddu = (to_dur.to_i * 60)
      end
    end
    
    if not stdu.nil? and not eddu.nil?
      dur_cond = "#{vl_tbl_name}.duration between '#{stdu}' and '#{eddu}'"
    elsif not stdu.nil?
      dur_cond = "#{vl_tbl_name}.duration >= '#{stdu}'"
    elsif not eddu.nil?
      dur_cond = "#{vl_tbl_name}.duration <= '#{eddu}'"
    end

    return dur_cond
    
  end
  
  def find_owner_agents

    agents = []

    if permission_by_name('tree_filter')
      
      grps_tmp1 = Group.select('id').where("leader_id = #{@app_user.id}") 
      grps_tmp2 = GroupMember.select('group_id').where({ :user_id => @app_user.id })
      
      grps_tmp = []
      grps_tmp = grps_tmp.concat(grps_tmp1.map { |x| x.id }) unless grps_tmp1.empty?
      grps_tmp = grps_tmp.concat(grps_tmp2.map { |x| x.group_id }) unless grps_tmp2.empty?

      unless grps_tmp.empty?
        agents = Agent.select('id').where("group_id in (#{grps_tmp.join(",")})")
        unless agents.empty?
          agents = agents.map { |y| y.id }
        end
        leaders = Group.select('leader_id').where("id in (#{grps_tmp.join(",")})")
        unless leaders.empty?
          agents = agents.concat(leaders.map { |y| y.leader_id })
        end
      end

      managers = find_manager_watch()
      agents = agents.concat(managers)

    else
      agents = nil
    end
    
    return agents
    
  end

  def find_manager_watch()
    managers = []
    mgs = GroupManager.where({ :user_id => @app_user.id })
    managers = mgs.map { |m| m.manager_id }
    
    return managers
  end
  
  def find_agent_by_agent(agent_id)
    return [agent_id]
  end

  def find_agent_by_agents(agents_id)
    agents 		= agents_id.split(",")
    agents_id = agents.compact.map { |a| a.to_i }
    
    return agents_id
  end
  
  def get_my_agent_id_list	
    set_current_user_for_call_search
    return find_owner_agents
  end
  
  def find_agent_by_group(groups_id)

    agents = []
 
    unless groups_id.empty?
			groups_id = groups_id.map {|g| g.to_i}
			if permission_by_name('tree_filter')
				grps_tmp1 = Group.select('id').where("id in (#{groups_id.join(",")}) and leader_id = #{@app_user.id}")
				
				grps_tmp2 = GroupMember.select('group_id').where({:user_id => @app_user.id})
				
				grps_tmp = []
				grps_tmp = grps_tmp.concat(grps_tmp1.map { |x| x.id.to_i }) unless grps_tmp1.empty?
				grps_tmp = grps_tmp.concat(grps_tmp2.map { |x| x.group_id.to_i }) unless grps_tmp2.empty?

				fgroups = groups_id & grps_tmp

				unless fgroups.empty?
					agents = Agent.select('id').where("group_id in (#{fgroups.join(",")})")
					unless agents.empty?
						agents = agents.map { |y| y.id }
					end
					leaders = Group.select('leader_id').where(["id in (?)",fgroups])
					unless leaders.empty?
						agents = agents.concat(leaders.map { |y| y.leader_id })
					end             
				end
			else
				agents = Agent.select('id').where("group_id in (#{groups_id.join(",")})")
				unless agents.empty?
					agents = agents.map { |y| y.id }
				end
				leaders = Group.select('leader_id').where(["id in (?)",groups_id])
				unless leaders.empty?
					agents = agents.concat(leaders.map { |y| y.leader_id })
				end              
			end
    else
			grps_tmp = Group.select('id').where("leader_id = #{@app_user.id}")
			unless grps_tmp.empty?
				grps_tmp = grps_tmp.map { |x| x.id }
				agents = Agent.select('id').where("group_id in (#{grps_tmp.join(",")})")
				unless agents.empty?
					agents = agents.map { |y| y.id }
				end
				leaders = Group.select('leader_id as id').where("id in (#{grps_tmp.join(",")})")
				unless leaders.empty?
					agents = agents.concat(leaders.map { |y| y.id })
				end               
			end
    end

    return agents

  end

  def find_agent_by_cate(cates)

    cates_tmp = cates.split(",")
    cates_tmp = cates_tmp.compact
    agents = []
    
    unless cates_tmp.empty?
      groups_id = GroupCategorization.select("group_id,count(id) as rec_count").where("group_category_id in (#{ cates_tmp.join(",") })").group('group_id')
      groups_id_tmp = (groups_id.map { |x| (x.rec_count.to_i == cates_tmp.length) ? x.group_id.to_i : nil }).compact
      agents = find_agent_by_group(groups_id_tmp)
    end

    return agents

  end
  
	def make_sql_for_eone(sc)
		
		vl_tblname 	= VoiceLogTemp.table_name
		
		# normal
		select					= []
		conditions  		= []
	  orders 					= []
		joins  					= []
		sqla  					= ""
		
		select = column_select_list
		
		joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
		
		# joins/wheres	
		sc[:conditions].each do |cond|
			condx = cond.clone
			case 0
			when condx =~ /(voice_logs)/, condx =~ /(\(voice_logs)/
					conditions << condx.gsub(vl_tblname,"v")
			when condx =~ /(voice_log_counters)/
				joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
				conditions << condx.gsub("voice_log_counters","c")
			when condx =~ /(result_keywords)/
				conditions << find_sql_result_keywords(condx,"v")
			when condx =~ /(taggings)/
				conditions << find_sql_taggings(condx,"v")
			when condx =~ /(voice_log_customers)/
				joins << "LEFT JOIN voice_log_customers cu ON v.id = cu.voice_log_id"
				conditions << condx.gsub("voice_log_customers","cu")
			end
		end
		
		# joins/orders
		sc[:order].each do |order|
			orderx = order.clone
			case 0
			when orderx =~ /(voice_log_counters)/
				joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
				orders << orderx.gsub("voice_log_counters","c")
			when orderx =~ /(users)/
				joins << "LEFT JOIN users u ON v.agent_id = u.id"
				orders << orderx.gsub("users","u")
			when orderx =~ /(voice_logs)/
				orders << orderx.gsub(vl_tblname,"v")
			end
		end
		
		# make
		joins = joins.uniq
		
		sqla = ""
		sqla << "SELECT #{select.join(",")} "
		sqla << "FROM #{vl_tblname} v #{joins.join(" ")} "
		sqla << "WHERE #{conditions.join(" AND ")} "
		if not orders.empty?
			sqla << "ORDER BY #{orders.join(",")} "
		end
		if (not sc[:limit] == false)
			sqla << "LIMIT #{sc[:limit]} "
			sqla << "OFFSET #{sc[:offset]} "
		end

		return sqla
	
	end
  
	def make_sql_for_eonesum(sc)
		
		vl_tblname 	= VoiceLogTemp.table_name
		
		# normal
		select					= []
		conditions			= []
		joins  					= []
		sqla  					= ""

	  select = column_select_sum
		
		joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
		
		# joins/wheres	
		sc[:conditions].each do |cond|
			condx = cond.clone
			case 0
			when condx =~ /(voice_logs)/, condx =~ /(\(voice_logs)/
					conditions << condx.gsub(vl_tblname,"v")
			when condx =~ /(voice_log_counters)/
				joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
				conditions << condx.gsub("voice_log_counters","c")
			when condx =~ /(result_keywords)/
				conditions << find_sql_result_keywords(condx,"v")
			when condx =~ /(taggings)/
				conditions << find_sql_taggings(condx,"v")
			when condx =~ /(voice_log_customers)/
				joins << "LEFT JOIN voice_log_customers cu ON v.id = cu.voice_log_id"
				conditions << condx.gsub("voice_log_customers","cu")
			end
		end
		
		# make
		joins = joins.uniq
	
		sqla = ""
		sqla << "SELECT #{select.join(",")} "
		sqla << "FROM #{vl_tblname} v #{joins.join(" ")} "
		sqla << "WHERE #{conditions.join(" AND ")} "

		return sqla

	end
  
	def make_sql_for_ext(sc)
		
		vl_tblname 			= VoiceLogTemp.table_name
		
		# normal
		select					= []
		conditions_all 	= []
		conditions  		= []
	  orders 					= []
		joins  					= []
		sqla  					= ""
		
		select = column_select_list
		vindex = get_index_key(sc)
		
		joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"

		# joins/wheres
		sc[:conditions].each do |cond|
			condx = cond.clone
			case 0
			when condx =~ /(voice_logs)/, condx =~ /(\(voice_logs)/
				if (condx =~ /start_time/) or (condx =~ /call_direction/)
					conditions_all << condx.gsub!(vl_tblname,"v")
				else
					conditions << condx.gsub(vl_tblname,"v")
				end
			when condx =~ /(voice_log_counters)/
				joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
				conditions << condx.gsub("voice_log_counters","c")
			when condx =~ /(result_keywords)/
				conditions << find_sql_result_keywords(condx,"v")
			when condx =~ /(taggings)/
				conditions << find_sql_taggings(condx,"v")
			when condx =~ /(voice_log_customers)/
				joins << "LEFT JOIN voice_log_customers cu ON v.id = cu.voice_log_id"
				conditions << condx.gsub("voice_log_customers","cu")
			when condx =~ /(voice_log_cars)/
				joins << "LEFT JOIN voice_log_cars cr ON v.id = cr.voice_log_id"
				conditions << condx.gsub("voice_log_cars","cr")				
			end
		end

		# joins/orders
		sc[:order].each do |order|
			orderx = order.clone
			case 0
			when orderx =~ /(voice_log_counters)/
				joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
				orders << orderx.gsub("voice_log_counters","c")
			when orderx =~ /(users)/
				joins << "LEFT JOIN users u ON v.agent_id = u.id"
				orders << orderx.gsub("users","u")
			when orderx =~ /(voice_logs)/
				orders << orderx.gsub(vl_tblname,"v")
			end
		end

		# show only main call
		conditions_all << "(v.ori_call_id IS NULL OR v.ori_call_id = '1')"
		 
		# exists where for transfered calls
		exists_where = ""
		if sc[:ctrl][:find_transfer]
			sqlb 				 = make_exists_sql_for_ext(sc)
			exists_where = "OR EXISTS (#{sqlb}) " unless sqlb.empty?
		end
		
		# make
		joins = joins.uniq
		
		sqla = ""
		sqla << "SELECT #{select.join(",")} "
		sqla << "FROM #{vl_tblname} v #{vindex} #{joins.join(" ")} "
		sqla << "WHERE #{conditions_all.join(" AND ")} "
		if not conditions.empty?
			sqlaa = "(#{conditions.join(" AND ")}) #{exists_where}"
			sqla << "AND (#{sqlaa}) "
		end
		if not orders.empty?
			sqla << "ORDER BY #{orders.join(",")} "
		end
		if (not sc[:limit] == false)
			sqla << "LIMIT #{sc[:limit]} "
			sqla << "OFFSET #{sc[:offset]} "
		end

		return sqla
	
	end

	def make_sql_for_extsum(sc)
		
		vl_tblname 	= VoiceLogTemp.table_name
		
		# normal
		select					= []
		conditions_all 	= []
		conditions			= []
		joins  					= []
		sqla  					= ""
		
	  select = column_select_sum
		vindex = get_index_key(sc)
		
		joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
		
		# joins/wheres
		sc[:conditions].each do |cond|
			condx = cond.clone
			case 0
			when condx =~ /(voice_logs)/, condx =~ /(\(voice_logs)/
				if (condx =~ /start_time/) or (condx =~ /call_direction/)
					conditions_all << condx.gsub(vl_tblname,"v")
				else
					conditions << condx.gsub(vl_tblname,"v")
				end
			when condx =~ /(voice_log_counters)/
				joins << "LEFT JOIN voice_log_counters c ON v.id = c.voice_log_id"
				conditions << condx.gsub("voice_log_counters","c")
			when condx =~ /(result_keywords)/
				conditions << find_sql_result_keywords(condx,"v")
			when condx =~ /(voice_log_customers)/
				conditions << condx.gsub("voice_log_customers","u")
			end
		end
		
		# exists where for transfered calls
		exists_where = ""
		if sc[:ctrl][:find_transfer]
			sqlb = make_exists_sql_for_ext(sc)
			exists_where = "OR EXISTS (#{sqlb}) " unless sqlb.empty?			
		end
		
		# show only main call
		conditions_all << "(v.ori_call_id IS NULL OR v.ori_call_id = '1')"
		
		# make
		joins = joins.uniq
		
		sqla = ""
		sqla << "SELECT #{select.join(",")} "
		sqla << "FROM #{vl_tblname} v #{vindex} #{joins.join(" ")} "
		sqla << "WHERE #{conditions_all.join(" AND ")} "
		if not conditions.empty?
			sqlaa = "(#{conditions.join(" AND ")}) #{exists_where}"
			sqla << "AND (#{sqlaa}) "
		end
		
		return sqla
	
	end

	def make_exists_sql_for_ext(sc)
		
		vl_tblname 			= VoiceLogTemp.table_name
		conditions_all 	= []
		conditions 			= []
		joins 					= []
	  sql 						= ""
	  
    sc[:conditions].each do |cond|
			condx = cond.clone
			case 0
			when condx =~ /(result_keywords)/
				joins << "JOIN result_keywords ks ON vs.id = ks.voice_log_id "
				conditions << condx.gsub("result_keywords","ks")
      when condx =~ /(voice_log_customers)/
				joins << "JOIN voice_log_customers cu ON vs.id = cu.voice_log_id "
				conditions << condx.gsub("voice_log_customers","cu")
      when condx =~ /(voice_log_cars)/
				joins << "JOIN voice_log_cars cr ON vs.id = cr.voice_log_id "
				conditions << condx.gsub("voice_log_cars","cr")
			when condx =~ /(voice_logs)/, condx =~ /(\(voice_logs)/
				if (condx =~ /(call_direction)/)
				elsif (condx =~ /(start_time)/) or (condx =~ /(duration)/)
					conditions_all << condx.gsub(vl_tblname,"vs")
				else
					conditions << condx.gsub(vl_tblname,"vs")
				end
			end
    end
    
    unless conditions.empty?
			
			conditions.concat(conditions_all)
			
			# select exists by call_id
			# conditions << "IFNULL(vs.ori_call_id,'1') <> '1'"
			conditions << "v.call_id = vs.ori_call_id"
		  
 		  # make sql
			sql =  "SELECT vs.id "
			sql << "FROM #{vl_tblname} vs "
			unless joins.empty?
				sql << "#{joins.join("")} "
			end
			sql << "WHERE #{conditions.join(" AND ")} "
			
		end

		return sql
  
	end
  
  def find_sql_result_keywords(cond,vl_prefix="v")
		
		condx 			= cond.clone
		conditions 	= []
		
		conditions << "#{condx.gsub("result_keywords","rs")}"
		conditions << "#{vl_prefix}.id = rs.voice_log_id)"
		sql = "EXISTS (SELECT rs.voice_log_id FROM result_keywords rs WHERE #{conditions.join(" AND ")}"		
		
		return sql
  
  end
  
  def find_sql_taggings(cond,vl_prefix="v")
		
		condx 			= cond.clone
		conditions 	= []
		
		conditions << condx.gsub("taggings","tg")
		conditions << "tg.taggable_type = 'VoiceLog'"
		conditions << "tg.context = 'tags'"
		conditions << "#{vl_prefix}.id = tg.taggable_id"
		sql = "EXISTS (SELECT tg.taggable_id FROM taggings tg WHERE #{conditions.join(" AND ")})"
		
		return sql
  
  end
  
  def find_agent_calls(sc={})

    voice_logs 	= []
    summary 		= {}
    page_info 	= {}
    
    # who search data
    set_current_user_for_call_search(sc[:ctrl][:user_id])
  
    # conditions
		filter_conds = voice_logs_default_filter
		sc[:conditions].concat(filter_conds) unless filter_conds.empty?
		sc[:conditions] = sc[:conditions].compact
		
		# orders
    if (not sc[:order].nil?) and (not sc[:order].empty?)
			sc[:order] = sc[:order].compact.join(',')
		end
    
    # voice_logs list
    voice_logs = []
    case Aohs::CURRENT_LOGGER_TYPE
		when :eone
			sql = make_sql_for_eone(sc)		
			voice_logs = VoiceLogTemp.find_by_sql(sql)
		when :extension
			if sc[:find_by_tag] == true
				sql = make_sql_for_eone(sc)		
				voice_logs = VoiceLogTemp.find_by_sql(sql)
			else
				sql = make_sql_for_ext(sc)		
				voice_logs = VoiceLogTemp.find_by_sql(sql)
			end
		end
  
		# voice_log summary
		total_records = voice_logs.length
    record_count 	= 0		
    summary 			= {
					:sum_dura => 0,
					:sum_ng => 0,
					:sum_mu => 0,
					:c_in => 0,
					:c_out => 0,
					:c_oth => 0
				}

    if total_records > 0 and sc[:summary] == true
			case Aohs::CURRENT_LOGGER_TYPE
			when :eone
				sql 	 = make_sql_for_eonesum(sc)
				result = VoiceLogTemp.find_by_sql(sql).first
			when :extension
				if sc[:find_by_tag] == true
					sql 	 = make_sql_for_eonesum(sc)
					result = VoiceLogTemp.find_by_sql(sql).first
				else
					sql 	 = make_sql_for_extsum(sc)
					result = VoiceLogTemp.find_by_sql(sql).first					
				end
			end
			
      unless result.nil?
        # default
        summary[:sum_dura] 	= result.duration.to_i
        summary[:sum_ng] 		= result.ng_word.to_i
        summary[:sum_mu] 		= result.mu_word.to_i
        summary[:c_in] 			= result.call_in.to_i
        summary[:c_out]	 		= result.call_out.to_i
        ##summary[:c_oth] 		= result.call_oth.to_i
        record_count 				= result.call_count.to_i
				
				# plus other values
				case Aohs::CURRENT_LOGGER_TYPE
				when :eone
				when :extension
					#summary[:c_in] 			+= result.call_in.to_i
					#summary[:c_out]	 		+= result.call_out.to_i					
					summary[:sum_dura]	+= result.trf_duration.to_i 
					summary[:sum_ng] 		+= result.trf_ng_count.to_i
					summary[:sum_mu] 		+= result.trf_must_count.to_i
				end
				
				# format
        summary[:sum_dura] 	= format_sec(summary[:sum_dura])
        summary[:sum_ng] 		= number_with_delimiter(summary[:sum_ng])
        summary[:sum_mu] 		= number_with_delimiter(summary[:sum_mu])
        summary[:c_in] 			= number_with_delimiter(summary[:c_in])
        summary[:c_out]	 		= number_with_delimiter(summary[:c_out])
        summary[:c_oth] 		= number_with_delimiter(summary[:c_oth])
      end
    end

    # page info
    
    page_info = {
				:page 				=> 'true',
				:total_page 	=> 0,
				:current_page => 0,
				:rec_count 		=> 0
		}

    if not sc[:page] == false
      page 				= sc[:page]
      total_page 	= ((record_count).to_f / sc[:perpage]).ceil
      page = 0 if total_page == 0
      sc[:page] = page
      page_info = {
					:page => 'true',
					:total_page => total_page,
					:current_page => page,
					:rec_count => record_count
			}
    end

    agents = find_owner_agents
    
    if Aohs::PRMVL_CHECK_NOTIN_MY
      sc[:limit_display_users] = true  
    end
    
    if sc[:limit_display_users] == true
      voice_logs = convert_voice_logs_info(voice_logs,agents,sc)
    else
      voice_logs = convert_voice_logs_info(voice_logs,false,sc)
    end
     
    sc = nil
    
    return voice_logs,summary, page_info, agents

  end
  
  def select_condition_for_main(cond)
    new_cond = []
    cond.each do |cond2|
      case cond2
        when /(direction)/
          new_cond << cond2
      end
    end
    return new_cond
  end
  
  def find_customer_calls(sc={})

    sc[:limit_display_users] = true
    
    voice_logs, summary, page_info, agents = find_agent_calls(sc)

    return voice_logs,summary, page_info, agents

  end

  def find_call_with_tags(sc={})
		
		sc[:find_by_tag] = true
		
		v 			= VoiceLogTemp.table_name
		# last six months ago
		fr_date = (Date.today-180).strftime("%Y-%m-%d 00:00:00")
		to_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
		tags_id = [0]
		
		# only six months ago
		sc[:conditions] << "#{v}.start_time BETWEEN '#{fr_date}' AND '#{to_date}'"
		
		# by tag group
    if not sc[:group_tag_id].empty? and sc[:group_tag_id].to_i > 0
      tag_group_id 	= sc[:group_tag_id].to_i
      tag_groups 		= TagGroup.includes(:tags).where({:id => tag_group_id}).all
      unless tag_groups.empty?
        tag_groups.each do |tg|
          tags_id.concat((tg.tags.map {|tag| tag.id }))
        end
      end
    end
    
    # by tag id
    if not sc[:tag_id].empty? and sc[:tag_id].to_i > 0
      tag_id 	= sc[:tag_id].to_i
      tag 		= Tags.where({:id => tag_id}).first
      if not tag.nil?
        tags_id << tag.id
      end
    end
    
    # by tag name
    if not sc[:tags].empty?
      tag_names = sc[:tags].to_s.strip  
      tags 			= Tags.where("name LIKE '#{tag_names}%'").all
      unless tags.empty?
        tags_id.concat((tags.map {|t| t.id })) 
      end
    end
    
    # add tag conditions
    tags_id = tags_id.join(",")
    sc[:conditions] << "taggings.tag_id IN (#{tags_id})"
    
		voice_logs,summary, page_info, agents = find_agent_calls(sc)
		  
    return voice_logs,summary, page_info, agents
    
  end

  def find_calls_for_timeline(sc={})

    tl_data = {}
    return tl_data
    
  end
  
  def find_transfer_calls(voice_log_id)
  
    vc = VoiceLogTemp.where({:id => voice_log_id}).first
    if not vc.nil?
      voice_logs = vc.transfer_calls  
      sc = {:tag_enabled => true}
      transfer_voice_logs = convert_voice_logs_info(voice_logs,false,{:perpage => 1, :page => 1, :ctrl => sc})
    else
      transfer_voice_logs = []
    end
    
    return transfer_voice_logs
    
  end
  
  def call_open?(agent_id,agents)
		
    is_open = true
    unless agents.nil?
       is_open = agents.include?(agent_id)
    end
	
    return is_open
    
  end

  def convert_voice_logs_info(voice_logs,agents,sc={})

    new_voice_logs 	= []
    ctrl 						= sc[:ctrl]

    unless voice_logs.blank?
      
      sc[:page] = valid_page_no(sc[:page])
      start_row = get_start_row_no(sc[:perpage],sc[:page]) 
		
      voice_logs.each_with_index do |vc,i|

        datetime 			= vc.start_time_full
				tags 					= "-"
        customer_name = ""
        customer_id 	= ""
        is_open 			= true
        agent_name 		= Aohs::UNKNOWN_AGENT_NAME        
        car_no 				= ""
        
				# tagging
        if ctrl[:tag_enabled] == true and vc.tags_exist?
					tags = vc.tag_list
        end

        if vc.agent_id.to_i > 0
          u = User.where(:id => vc.agent_id).first rescue nil
          unless u.nil?
            agent_name = u.display_name  
            if not agents == false
							is_open = call_open?(vc.id,agents)
            end
          end
        end

				if Aohs::MOD_CUSTOMER_INFO
					unless vc.voice_log_customer.nil?
						unless vc.voice_log_customer.customer.nil?
              customer_id = vc.voice_log_customer.customer.id
              customer_name = vc.voice_log_customer.customer.customer_name rescue ""
            end
          end
				end
      
        if Aohs::MOD_CUST_CAR_ID and Aohs::MOD_CUSTOMER_INFO
          unless vc.voice_log_cars.empty?
            car_no = []
            vc.voice_log_cars.each do |c|
              unless c.car_number.nil?
                car_no << format_car_id(c.car_number.car_no)
              end
            end
            car_no = car_no.join(",")
          end
        end
      
        is_found_transfer = false
        vc_ng_count = 0
        vc_must_count = 0
        vc_book_count = 0
        vc_tranfered_count = 0
        begin
					vc_ng_count 	= vc.ngword_count.to_i
					vc_must_count = vc.mustword_count.to_i
					vc_book_count = vc.bookmark_count.to_i
					vc_tranfered_count = vc.trf_call_count #vc.transfer_call_count.to_i
				rescue
					vcc = vc.voice_log_counter
					vc_ng_count 	= vcc.ngword_count.to_i
					vc_must_count = vcc.mustword_count.to_i
					vc_book_count = vcc.bookmark_count.to_i
					vc_tranfered_count = vcc.transfer_call_count.to_i
				end 
				if Aohs::MOD_CALL_TRANSFER
					is_found_transfer = vc.have_transfered_call?(vc_tranfered_count)
				end

        xduration = vc.duration.to_i
        xextension = vc.extension_number.to_s
        
        new_voice_logs << {
            :no => (i+1)+start_row,
            :id => vc.id,
            :sid => vc.system_id,
            :did => vc.device_id,
            :cid => vc.channel_id,
            :sdate => "#{default_datetime_format(datetime)}",
            :edate => "#{default_datetime_format(datetime + xduration)}",
            :v_st => "#{default_time_format(datetime)}",
            :v_en => "#{default_time_format(datetime + xduration)}",
            :duration => "#{format_sec(xduration)}",
            :dmin => (xduration/60),
            :ani => format_phone(vc.ani),
            :dnis => format_phone(vc.dnis),
            :ext => xextension,
            :agent => agent_name,
            :cust => customer_name,
            :cust_id => customer_id,
            :car_no => car_no,
            :cd => vc.call_direction_name,
            :cd_c => vc.call_direction,
            :ngc => vc_ng_count,
            :mustc => vc_must_count,
            :bookc => vc_book_count,
            :tags => tags,
            :path => vc.disposition,
            :open => is_open,
            :trfc => is_found_transfer,
            :offset_sec => vc.start_position_sec
        }
        
        if is_found_transfer and (ctrl[:show_sub_call] == true)
          ## add transfer log
          trfs = find_transfer_calls(vc.id)
          unless trfs.empty?
            trfs.each do |t|
              t[:child] = true
              new_voice_logs << t
            end
          end
        end
        
      end
    end
	
    voice_logs = nil
    return new_voice_logs

  end
  
  def valid_page_no(page=1)
    return ((page.to_i <= 0) ? 1 : page.to_i)
  end
  
  def get_start_row_no(perpage,page)
    return perpage * (page.to_i-1)
  end
  
  private
  
  def column_select_list

	  cols = [
					:id,
					:system_id,
					:device_id,
					:channel_id,
					:ani,
					:dnis,
					:extension,
					:duration,
					:agent_id,
					:voice_file_url,
					:call_direction,
					:start_time,
					:call_id
		]
	  cols_counter = [
					:ngword_count,
					:mustword_count,
					:bookmark_count,
					"transfer_call_count AS trf_call_count"
		]
	  
    case Aohs::CURRENT_LOGGER_TYPE
		when :eone
		when :extension
			cols.concat([
					:ori_call_id,
					:answer_time					 
			])
			cols_counter.concat([
					:transfer_call_count
			])
		end
    
	  select = cols.map { |c| "v.#{c.to_s}" }
		select.concat(cols_counter.map { |c| "c.#{c.to_s}"})
	  
	  return select
  
	end
	
	def column_select_sum
		
	  cols = [
					"COUNT(v.id) AS call_count",
					"SUM(v.duration) AS duration",
					"SUM(c.ngword_count) AS ng_word",
					"SUM(c.mustword_count) AS mu_word",
					"SUM(IF(v.call_direction = 'i',1,0)) as call_in",
					"SUM(IF(v.call_direction = 'o',1,0)) as call_out"

		]

    case Aohs::CURRENT_LOGGER_TYPE
		when :eone
		when :extension
			cols.concat([
					"SUM(c.transfer_in_count) AS trf_in",
					"SUM(c.transfer_out_count) AS trf_out",
					"SUM(c.transfer_duration) AS trf_duration",
					"SUM(c.transfer_ng_count) AS trf_ng_count",
					"SUM(c.transfer_must_count) AS trf_must_count",
			])
		end
	  
	  return cols
	
	end

  def voice_logs_default_filter
	
		conditions 	= []
		v = VoiceLogTemp.table_name
		
		# default filter
		if Aohs::VFILTER_DURATION_MIN.to_i > 0
			conditions << "#{v}.duration >= #{Aohs::VFILTER_DURATION_MIN.to_i}"
		end
		
		# default call selection
    case Aohs::CURRENT_LOGGER_TYPE
		when :eone
			#
		when :extension
		  #
		end
    
		return conditions
  
	end
	
	def get_index_key(sc)
		
		sql_index = ""
		
		# default
		#indexs = [
		#				"index_voice_logs_on_start_time",
		#				"index_voice_logs_on_ani",
		#				"index_voice_logs_on_dnis",
		#				"vc_index1"
		#]
		#sql_index = "USE INDEX (#{indexs.join(",")})"
		
		return sql_index
	
	end
	
end