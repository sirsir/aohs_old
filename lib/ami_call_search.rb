
module AmiCallSearch
 
  def set_current_user_for_call_search(user_id=nil)

    @app_user = nil
    
    if not user_id.nil? and user_id.to_i > 0 
      @app_user = User.where({:id => user_id }).first
    else
      @app_user = User.where({:id => current_user.id}).first
    end

    @app_user = nil if @app_user.nil?
    
  end
 
  def retrive_sort_columns(sort_by,order_by="desc")

    orders = []

    vl_cols = VoiceLogTemp.new.attribute_names.to_a
    vc_cols = VoiceLogCounter.new.attribute_names.to_a
    vl_tbl_name = VoiceLogTemp.table_name
    
    unless sort_by.blank?
      if vl_cols.include?(sort_by)
        orders << "#{vl_tbl_name}.#{sort_by} #{order_by}"
      elsif ['agent'].include?(sort_by)
        orders << "users.login #{order_by}"
      elsif ['agent_name'].include?(sort_by)
          orders << "users.login #{order_by}"        
      elsif ['customer'].include?(sort_by)
        orders << "customers.name #{order_by}"
      elsif vc_cols.include?(sort_by)
        orders << "voice_log_counters.#{sort_by} #{order_by}"
      else
        orders << "#{vl_tbl_name}.start_time desc"
      end
    else
      orders << "#{vl_tbl_name}.start_time desc"
    end

    return orders
    
  end

  def retrive_datetime_condition(period_type,st_date,st_time,ed_date,ed_time)

    dt_cond = nil

    vl_tbl_name = VoiceLogTemp.table_name
    
    unless period_type.blank?
      period_type = period_type.to_i
    else
      period_type = 1
    end

    now = Date.today
    case period_type
      when 1 #today
        dt_cond = "#{vl_tbl_name}.start_time between '#{now} 00:00:00' and '#{now} 23:59:59'"
      when 2 #yesterday
        yesterday = now - 1
        dt_cond = "#{vl_tbl_name}.start_time between '#{yesterday} 00:00:00' and '#{yesterday} 23:59:59'"
      when 3 #this week
        dt_cond = "#{vl_tbl_name}.start_time between '#{now.beginning_of_week} 00:00:00' and '#{now.end_of_week} 23:59:59'"
      when 4 #last week
        last_week = (now.beginning_of_week - 1)
        dt_cond = "#{vl_tbl_name}.start_time between '#{last_week.beginning_of_week} 00:00:00' and '#{last_week.end_of_week} 23:59:59'"
      when 5 #this month
        dt_cond = "#{vl_tbl_name}.start_time between '#{now.beginning_of_month} 00:00:00' and '#{now.end_of_month} 23:59:59'"
      when 6 #last month
        last_month = (now.beginning_of_month - 1)
        dt_cond = "#{vl_tbl_name}.start_time between '#{last_month.beginning_of_month} 00:00:00' and '#{last_month.end_of_month} 23:59:59'"
      when 7 #this year
        dt_cond = "#{vl_tbl_name}.start_time between '#{now.beginning_of_year} 00:00:00' and '#{now.end_of_year} 23:59:59'"
      when 8 #all => Search all
        dt_cond = "#{vl_tbl_name}.start_time >= '#{now - Aohs::LIMIT_SEARCH_DAYS} 00:00:00'"
	  when 9 # one month ago
		month_later = now - 30 
		dt_cond = "#{vl_tbl_name}.start_time between '#{month_later} 23:59:59' and '#{now} 00:00:00'"
	  when 10 # six month ago
		six_month_later = now - (6 * 30)
		dt_cond = "#{vl_tbl_name}.start_time between '#{six_month_later} 23:59:59' and '#{now} 00:00:00'"
	  when 11 # one week ago
		dt_cond = "#{vl_tbl_name}.start_time between '#{now - 7} 00:00:00' and '#{now} 23:59:59'"
      when 0 #custom ...
         stdate = nil
         sttime = nil
         eddate = nil
         edtime = nil
         if not st_date.blank?
           stdate = Date.parse(st_date).strftime("%Y-%m-%d")
         end
         if not st_time.blank? and st_time.to_s =~ /(\d\d):(\d\d)/
           sttime = Time.parse(st_time).strftime("%H:%M:%S")
         end
         if not ed_date.blank?
           eddate = Date.parse(ed_date).strftime("%Y-%m-%d")
         end
         if not ed_time.blank? and ed_time.to_s =~ /(\d\d):(\d\d)/
           edtime = Time.parse(ed_time).strftime("%H:%M:%S")
         end
         
         if not stdate.blank? and not sttime.blank? and not eddate.blank? and not edtime.blank?
           dt_cond = "#{vl_tbl_name}.start_time between '#{stdate} #{sttime}' and '#{eddate} #{edtime}'"
         elsif not stdate.blank? and not sttime.blank? and not eddate.blank?
           dt_cond = "#{vl_tbl_name}.start_time between '#{stdate} #{sttime}' and '#{eddate} 23:59:59'"
         elsif not stdate.blank? and not eddate.blank? and not edtime.blank?
           dt_cond = "#{vl_tbl_name}.start_time between '#{stdate} 00:00:00' and '#{eddate} #{edtime}'"
         elsif not stdate.blank? and not sttime.blank?
           dt_cond = "#{vl_tbl_name}.start_time >= '#{stdate} #{sttime}'"
         elsif not stdate.blank? and not eddate.blank?
           dt_cond = "#{vl_tbl_name}.start_time between '#{stdate} 00:00:00' and '#{eddate} 23:59:59'"
         elsif not eddate.blank? and not edtime.blank?
           dt_cond ="#{vl_tbl_name}.start_time <= '#{eddate} #{edtime}'"
         elsif not eddate.blank?
           dt_cond = "#{vl_tbl_name}.start_time <= '#{eddate} 23:59:59'"
         elsif not stdate.blank?
           dt_cond = "#{vl_tbl_name}.start_time >= '#{stdate} 00:00:00'"
         end

     end

    return dt_cond
    
  end

  def retrive_duration_conditions(from_dur,to_dur)

    vl_tbl_name = VoiceLogTemp.table_name
    dur_cond = nil

    stdu = nil
    eddu = nil
    unless from_dur.blank?
      if (from_dur.strip =~ /^([0-9]+):([0-9]+)$/) != nil
        d = from_dur.split(':')
        stdu = (d.first.to_i * 60) + d.last.to_i
      else
        stdu = (from_dur.to_i * 60)
      end
    end
    unless to_dur.blank?
      if (to_dur.strip =~ /^([0-9]+):([0-9]+)$/) != nil
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

    agents = agents_id.split(",")
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
  
  def voice_logs_transfer_query_builder(includes,joins,sc={})
    
    v = VoiceLogTemp.table_name
    includes = (includes.concat(joins)).uniq
    
    sql = ""
    sql << "SELECT IF((#{v}.ori_call_id = 1 OR #{v}.ori_call_id = '' OR #{v}.ori_call_id is null),#{v}.call_id,#{v}.ori_call_id) AS xcall_id "
    
    sql_frm = "#{v}"
    if includes.include?(:voice_log_counter)
      sql_frm = "(#{sql_frm} JOIN voice_log_counters ON #{v}.id = voice_log_counters.voice_log_id)"
    end
    if includes.include?(:result_keywords)
      sql_frm = "(#{sql_frm} LEFT JOIN result_keywords ON #{v}.id = result_keywords.voice_log_id)"
    end
    if includes.include?(:voice_log_customer)
      sql_frm = "(#{sql_frm} LEFT JOIN voice_log_customers ON #{v}.id = voice_log_customers.voice_log_id)"
    end
    if includes.include?(:voice_log_cars)
      sql_frm = "(#{sql_frm} LEFT JOIN voice_log_cars ON #{v}.id = voice_log_cars.voice_log_id)"
    end
    if includes.include?(:taggings)
      sql_frm = "(#{sql_frm} LEFT JOIN taggings ON #{v}.id = taggings.taggable_id)"  
    end
    
    sql << " FROM #{sql_frm} "
    sql << " WHERE #{sc[:conditions].join(' AND ')}" unless sc[:conditions].empty?
    sql << " GROUP BY xcall_id "

    return sql
    
  end
  
  def voice_logs_joins_query_builder(includes,joins,sc={})
		
	v = VoiceLogTemp.table_name
	  includes = (includes.concat(joins)).uniq
	    
	  sql_frm = "#{v}"
	  if includes.include?(:voice_log_counter)
		sql_frm = "(#{sql_frm} JOIN voice_log_counters ON #{v}.id = voice_log_counters.voice_log_id)"
	  end          
	  if includes.include?(:result_keywords)
		sql_frm = "(#{sql_frm} LEFT JOIN result_keywords ON #{v}.id = result_keywords.voice_log_id)"
	  end
	  if includes.include?(:voice_log_customer)
		sql_frm = "(#{sql_frm} LEFT JOIN voice_log_customers ON #{v}.id = voice_log_customers.voice_log_id)"
	  end
	  if includes.include?(:voice_log_cars)
		sql_frm = "(#{sql_frm} LEFT JOIN voice_log_cars ON #{v}.id = voice_log_cars.voice_log_id)"
	  end 
	  if includes.include?(:taggings)
		sql_frm = "(#{sql_frm} LEFT JOIN taggings ON #{v}.id = taggings.taggable_id)"  
	  end  
	
	  return sql_frm
  end
  
  def voice_logs_summary_query_builder(includes,joins,sc={})
    
    v = VoiceLogTemp.table_name
    c = VoiceLogCounter.table_name
    
    select_sql = ""
    sql = ""
    
    case Aohs::CURRENT_LOGGER_TYPE
      when :eone 
          
          includes = (includes.concat(joins)).uniq
          
          select_sql << " COUNT(v.id) AS call_count,SUM(v.duration) AS duration,SUM(v.ngword_count) AS ng_word, sum(v.mustword_count) as mu_word, "
          select_sql << " SUM(IF(v.call_direction = 'i',1,0)) AS call_in, "
          select_sql << " SUM(IF(v.call_direction = 'o',1,0)) AS call_out, "
          select_sql << " SUM(IF((v.call_direction in ('e','u')),1,0)) AS call_oth " 
          
          sql_frm = "#{v}"
          if includes.include?(:voice_log_counter)
            sql_frm = "(#{sql_frm} JOIN voice_log_counters on #{v}.id = voice_log_counters.voice_log_id)"
          end          
          if includes.include?(:result_keywords)
            sql_frm = "(#{sql_frm} LEFT JOIN result_keywords on #{v}.id = result_keywords.voice_log_id)"
          end
          if includes.include?(:voice_log_customer)
            sql_frm = "(#{sql_frm} LEFT JOIN voice_log_customers on #{v}.id = voice_log_customers.voice_log_id)"
          end
          if includes.include?(:voice_log_cars)
            sql_frm = "(#{sql_frm} LEFT JOIN voice_log_cars on #{v}.id = voice_log_cars.voice_log_id)"
          end 
          if includes.include?(:taggings)
            sql_frm = "(#{sql_frm} LEFT JOIN taggings ON #{v}.id = taggings.taggable_id)"  
          end  
          
          sql << " SELECT #{v}.id,#{v}.call_direction,#{v}.duration,#{c}.ngword_count,#{c}.mustword_count "
          sql << " FROM #{sql_frm} "
          sql << " WHERE #{sc[:conditions].join(' and ')} "
          sql << " GROUP BY #{v}.id "
          
          sql = "SELECT #{select_sql} FROM (#{sql}) v "
          
      when :extension
         sql_where = nil
        case Aohs::VLOG_SUMMARY_BY
        when :normal_or_main
          select_sql << " COUNT(distinct v.id) AS call_count,SUM(v.duration) AS duration,SUM(v.ngword_count) AS ng_word, sum(v.mustword_count) as mu_word, "
          select_sql << " SUM(IF(v.call_direction = 'i',1,0)) as call_in, "
          select_sql << " SUM(IF(v.call_direction = 'o',1,0)) as call_out, "
          select_sql << " SUM(IF((v.call_direction in ('e','u')),1,0)) AS call_oth " 
          sql << " SELECT #{v}.id,#{v}.call_direction,(#{v}.duration + IFNULL(#{c}.transfer_duration,0)) as duration,(#{c}.ngword_count + IFNULL(#{c}.transfer_ng_count,0)) as ngword_count,(#{c}.mustword_count + IFNULL(#{c}.transfer_must_count,0)) as mustword_count "
		  if sc[:ctrl][:find_transfer] == true
			sql_frm = "#{v} JOIN (#{voice_logs_transfer_query_builder(includes,[],sc)}) transfer_log ON #{v}.call_id = transfer_log.xcall_id LEFT JOIN #{c} ON #{v}.id = #{c}.voice_log_id "
		  else
		    includes << :voice_log_counter
			sql_frm = "#{voice_logs_joins_query_builder(includes,joins,sc)}" 
			sql_where = "#{sc[:conditions].join(' and ')}"
		  end
		when :inc_trf
          select_sql << " COUNT(distinct v.id) AS call_count,SUM(v.duration) AS duration,SUM(v.ngword_count) AS ng_word, sum(v.mustword_count) as mu_word, "
          select_sql << " SUM(IF(v.call_direction = 'i',1,0) + IFNULL(v.transfer_in_count,0)) AS call_in, "
          select_sql << " SUM(IF(v.call_direction = 'o',1,0) + IFNULL(v.transfer_out_count,0)) AS call_out, "
          select_sql << " SUM(IF((v.call_direction in ('e','u')),1,0)) AS call_oth " 
          sql << " SELECT #{v}.id,#{v}.call_direction,(#{v}.duration + IFNULL(#{c}.transfer_duration,0)) as duration,(#{c}.ngword_count + IFNULL(#{c}.transfer_ng_count,0)) as ngword_count,(#{c}.mustword_count + IFNULL(#{c}.transfer_must_count,0)) as mustword_count, #{c}.transfer_in_count, #{c}.transfer_out_count "
          sql_frm = "#{v} JOIN (#{voice_logs_transfer_query_builder(includes,[],sc)}) transfer_log ON #{v}.call_id = transfer_log.xcall_id LEFT JOIN #{c} ON #{v}.id = #{c}.voice_log_id "

		  if sc[:ctrl][:find_transfer] == true
			sql_frm = "#{v} JOIN (#{voice_logs_transfer_query_builder(includes,[],sc)}) transfer_log ON #{v}.call_id = transfer_log.xcall_id LEFT JOIN #{c} ON #{v}.id = #{c}.voice_log_id "
		  else
		    includes << :voice_log_counter
			sql_frm = "#{voice_logs_joins_query_builder(includes,joins,sc)}" 
			sql_where = "#{sc[:conditions].join(' and ')}"
		  end  
		when :search_only
          # not define
        end      
      
        sql << " FROM #{sql_frm} "
		sql << " WHERE #{sql_where} " unless sql_where.nil?
		sql << " GROUP BY #{v}.id "
        sql = "SELECT #{select_sql} FROM (#{sql}) v"  
    
    else
      # error
    end

    return sql      
    
  end
  
  def voice_logs_default_filter
	
	conditions = []
	
	v = VoiceLogTemp.table_name
	if Aohs::VFILTER_DURATION_MIN.to_i > 0
		conditions << "#{v}.duration >= #{Aohs::VFILTER_DURATION_MIN.to_i}"
	end
	
	return conditions
	
  end
  
  def find_agent_calls(sc={})

    vl_tbl_name = VoiceLogTemp.table_name
    vlc_tbl = VoiceLogCounter.table_name
    
    set_current_user_for_call_search(sc[:ctrl][:user_id])
    
    voice_logs = []
    summary = {}
    page_info = {}
          
    # -- voice_logs filter --
	if Aohs::ENABLE_DEFAULT_VFILTER
		filter_conds = voice_logs_default_filter
		sc[:conditions] = sc[:conditions].concat(filter_conds) unless filter_conds.empty?
	end
	
    # -- voice_logs data --
	
    sc[:conditions] = sc[:conditions].compact
    sc[:order] = sc[:order].compact.join(',') unless sc[:order].blank? 
      
    # for search
    joins = []
    includes = [:user]
    # for count and summary 
    joins2 = [:voice_log_counter]      
    includes2 = []
    
    sc[:conditions].each do |cond|
      if cond =~ /(voice_log_counters)/ or sc[:order] =~ /(voice_log_counters)/
        includes << :voice_log_counter
        joins2 << :voice_log_counter       
      end
      if cond =~ /(result_keywords)/
        includes << :result_keywords
        joins2 << :result_keywords
      end
      if cond =~ /(voice_log_customers)/
        includes << :voice_log_customer
        joins2 << :voice_log_customer   
      end
      if cond=~ /(voice_log_cars)/
        includes << :voice_log_cars
        joins2 << :voice_log_cars        
      end
    end
    includes = includes.uniq
    joins2 = joins2.uniq 
    
    cols1 = [:id,:system_id,:device_id,:channel_id,:ani,:dnis,:extension,:duration,:agent_id,:voice_file_url,:call_direction,:start_time,:call_id,:ori_call_id,:answer_time] 
    cols1 = cols1.map { |c| "#{vl_tbl_name}.#{c.to_s}" }
    selects = cols1.join(",")

    voice_logs = []
    case Aohs::CURRENT_LOGGER_TYPE
      when :eone
        # normal table
        voice_logs = VoiceLogTemp.includes(includes).joins(joins).where(sc[:conditions].join(' and ')).order(sc[:order]).group("#{vl_tbl_name}.id").limit(sc[:limit]).offset(sc[:offset])  
      when :extension
        # transfer table
        
        # find include sub
        if sc[:ctrl][:timeline_enabled] == true && false
          voice_logs = VoiceLogTemp.select(selects).includes(includes).joins(joins).where(sc[:conditions].join(' and ')).order(sc[:order]).group("#{vl_tbl_name}.id").limit(sc[:limit]).offset(sc[:offset])
        else
		  if sc[:ctrl][:find_transfer] == true
			  main_condition = select_condition_for_main(sc[:conditions])
			  main_condition << "(#{vl_tbl_name}.ori_call_id = 1 or #{vl_tbl_name}.ori_call_id = '' or #{vl_tbl_name}.ori_call_id is null)"
			  sql_joins = voice_logs_transfer_query_builder(includes,joins,sc)
			  sql_joins = "join (#{sql_joins}) transfer_log on transfer_log.xcall_id = #{vl_tbl_name}.call_id "
			  if sc[:order] =~ /(voice_log_counter)/
				sql_joins << "left join voice_log_counters on #{vl_tbl_name}.id = voice_log_counters.voice_log_id " 
			  end
			  if sc[:order] =~ /(users)/
				sql_joins << "left join users on #{vl_tbl_name}.agent_id = users.id " 
			  end         
			  voice_logs = VoiceLogTemp.select(selects).joins(sql_joins).order(sc[:order]).where(main_condition.join(" AND ")).group("#{vl_tbl_name}.id").limit(sc[:limit]).offset(sc[:offset])                
		  else
			  sc[:conditions] << "(#{vl_tbl_name}.ori_call_id = 1 or #{vl_tbl_name}.ori_call_id = '' or #{vl_tbl_name}.ori_call_id is null)"
			  voice_logs = VoiceLogTemp.select(selects).includes(includes).joins(joins).where(sc[:conditions].join(' and ')).order(sc[:order]).group("#{vl_tbl_name}.id").limit(sc[:limit]).offset(sc[:offset])  
		  end
        end
    end
   
    # -- summary data --
    
    STDOUT.puts "length= #{voice_logs.length}"
    
    sc[:limit] = false
    sc[:offset] = false
    
    summary = {:sum_dura => 0, :sum_ng => 0, :sum_mu => 0,:c_in => 0,:c_out => 0,:c_oth => 0}
    record_count = 0
    
    if not voice_logs.empty? and sc[:summary] == true
      
      v = VoiceLogTemp.table_name
      c = VoiceLogCounter.table_name
      
      sql = voice_logs_summary_query_builder(includes2,joins2,sc)
      result = VoiceLogTemp.find_by_sql(sql).first
      
      unless result.blank?
        summary[:sum_dura] = format_sec(result.duration.to_i)
        summary[:sum_ng] = number_with_delimiter(result.ng_word.to_i)
        summary[:sum_mu] = number_with_delimiter(result.mu_word.to_i)
        summary[:c_in] = number_with_delimiter(result.call_in.to_i)
        summary[:c_out] = number_with_delimiter(result.call_out.to_i)
        summary[:c_oth] = number_with_delimiter(result.call_oth.to_i)
        record_count = result.call_count.to_i
      end

    end

    # page info
    
    page_info = { :page => 'true', :total_page => 0,:current_page => 0, :rec_count => 0, :tl_stdate => "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" }

    if not sc[:page] == false
      page = sc[:page]
      total_page = ((record_count).to_f / sc[:perpage]).ceil
      page = 0 if total_page == 0
      tl_start_date = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" if total_page == 0
      sc[:page] = page
      page_info = { :page => 'true', :total_page => total_page, :current_page => page, :rec_count => record_count, :tl_stdate => tl_start_date.nil? ? "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" : tl_start_date }
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

    v = VoiceLogTemp.table_name
    
    set_current_user_for_call_search(sc[:ctrl][:user_id])
    skip_search = false
    
    summary = {}
    page_info = {}
    conditions = []
    
    tags_id = []  
      
    if not sc[:group_tag_id].empty? and sc[:group_tag_id].to_i > 0
      tag_group_id = sc[:group_tag_id].to_i
      
      tag_groups = TagGroup.includes(:tags).where({:id => tag_group_id})
      unless tag_groups.empty?
        tag_groups.each do |tg|
          tags_id.concat((tg.tags.map {|tag| tag.id }))
        end
      end
      skip_search = true if tags_id.empty? # tag group not have tags
    end
    
    if not sc[:tag_id].empty? and sc[:tag_id].to_i > 0
      tag_id = sc[:tag_id].to_i
      
      tag = Tags.where({:id => tag_id}).first
      if tag.nil?
        skip_search = true
      else
        skip_search = false
        tags_id << tag.id
      end
    end
      
    if not sc[:tags].empty?
      tag_names = sc[:tags].to_s.strip
      
      tags = Tags.where("name like '#{tag_names}%'").all
      unless tags.empty?
        tags_id.concat((tags.map {|tag| tag.id })) 
        skip_search = false
      else
        skip_search = true
      end
    end
    
    if tags_id.empty?
      # all tag
    else
      tags_id = tags_id.join(",")
      conditions << "taggings.tag_id IN (#{tags_id})"
    end
    
    conditions << "(taggings.taggable_type = 'VoiceLog' AND taggings.context = 'tags')"
    
    # current agent
    agents = find_owner_agents
    unless agents.nil?
      unless agents.empty?
        conditions << "(#{v}.agent_id in (#{agents.join(',')}) or #{v}.agent_id is null or #{v}.agent_id = 0)"
      end
    end
    
    includes = [:taggings,:user,:voice_log_counter]
    joins = []
    
    sc[:conditions] = sc[:conditions].concat(conditions)
    sc[:order] = sc[:order].compact.join(',') unless sc[:order].blank? 
    
    voice_logs = []
    summary = {:sum_dura => 0, :sum_ng => 0, :sum_mu => 0,:c_in => 0,:c_out => 0,:c_oth => 0}
    
    if not skip_search
                     
      voice_logs = []
      case Aohs::CURRENT_LOGGER_TYPE
        when :eone
          # normal table
          voice_logs = VoiceLogTemp.includes(includes).joins(joins).where(sc[:conditions].join(' and ')).order(sc[:order]).group("#{v}.id").limit(sc[:limit]).offset(sc[:offset])  
        when :extension
          # transfer table
          sql_joins = voice_logs_transfer_query_builder(includes,joins,sc)
          sql_joins = "join (#{sql_joins}) transfer_log on transfer_log.xcall_id = #{v}.call_id"
          voice_logs = VoiceLogTemp.joins(sql_joins).includes(includes).order(sc[:order]).where("(#{v}.ori_call_id = 1 or #{v}.ori_call_id = '' or #{v}.ori_call_id is null)").group("#{v}.id").limit(sc[:limit]).offset(sc[:offset])               
        else
          # error
      end
      
      STDOUT.puts "length=#{voice_logs.length}"
      
      if not voice_logs.empty? and sc[:summary] == true
        
        v = VoiceLogTemp.table_name
        c = VoiceLogCounter.table_name
        
        sql = voice_logs_summary_query_builder(includes,joins,sc)
        result = VoiceLogTemp.find_by_sql(sql).first
        
        unless result.blank?
          summary[:sum_dura] = format_sec(result.duration.to_i)
          summary[:sum_ng] = number_with_delimiter(result.ng_word.to_i)
          summary[:sum_mu] = number_with_delimiter(result.mu_word.to_i)
          summary[:c_in] = number_with_delimiter(result.call_in.to_i)
          summary[:c_out] = number_with_delimiter(result.call_out.to_i)
          summary[:c_oth] = number_with_delimiter(result.call_oth.to_i)
          record_count = result.call_count.to_i
        end
  
      end
      
    end
    
    # page info
    
    page_info = { :page => 'true', :total_page => 0,:current_page => 0, :rec_count => 0, :tl_stdate => "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" }

    if not sc[:page] == false
      page = sc[:page]
      total_page = ((record_count).to_f / sc[:perpage]).ceil
      page = 0 if total_page == 0
      tl_start_date = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" if total_page == 0
      sc[:page] = page
      page_info = { :page => 'true', :total_page => total_page, :current_page => page, :rec_count => record_count, :tl_stdate => tl_start_date.nil? ? "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" : tl_start_date }
    end    

    agents = nil

    voice_logs = convert_voice_logs_info(voice_logs,agents,sc)
    
    return voice_logs,summary, page_info, agents
    
  end

  def find_calls_for_timeline(sc={})

    vl_tbl_name = VoiceLogTemp.table_name

    tl_data = {}
    
    sc[:summary] = false
    sc[:page] = true
    sc[:order] = ["#{vl_tbl_name}.agent_id,#{vl_tbl_name}.start_date asc,#{vl_tbl_name}.start_time asc"]
    
    voice_logs, summary, page_info, agents = find_agent_calls(sc)

    unless voice_logs.empty?
      min_dt = nil
      max_dt = nil
      current_agent = nil
      
      voice_logs.each do |vl|

        datetime = Time.local(vl.start_date.year, vl.start_date.month, vl.start_date.day, vl.start_time.hour, vl.start_time.min, vl.start_time.sec)

        if tl_data[vl.agent_name].nil?
           tl_data[vl.agent_name] = [""]
        end
            
        if current_agent != vl.agent_name
          min_dt = datetime
          tl_data[current_agent] = [""]
        else
          max_dt = datetime + vl.duration.to_i
          tl_data[current_agent].first = "x,#{min_dt.strftime('%Y-%m-%d %H:%M:%S')},#{(max_dt + vl.duration.to_i).strftime('%Y-%m-%d %H:%M:%S')}"
        end

        tl_data[current_agent] << "#{vl.call_direction},#{datetime.strftime('%Y-%m-%d %H:%M:%S')},#{(datetime + vl.duration.to_i).strftime('%Y-%m-%d %H:%M:%S')}"

      end
    end

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

    new_voice_logs = []
    ctrl = sc[:ctrl]

    unless voice_logs.blank?
      
      sc[:page] = valid_page_no(sc[:page])
      start_row = get_start_row_no(sc[:perpage],sc[:page]) 
		
      voice_logs.each_with_index do |vc,i|

        datetime = vc.start_time_full

        tags = "-"
        if ctrl[:tag_enabled] == true
          if vc.tags_exist?
            tags = vc.tag_list
          end
        end

        is_open = true
        agent_name = Aohs::UNKNOWN_AGENT_NAME
        if vc.agent_id.to_i > 0
          u = vc.user
          unless u.nil?
            agent_name = u.display_name  
            if not agents == false
              is_open = call_open?(vc.agent_id,agents)
            end
          end
        end

        customer_name = ""
        customer_id = ""
          if Aohs::MOD_CUSTOMER_INFO
          unless vc.voice_log_customer.nil?
           unless vc.voice_log_customer.customer.nil?
              customer_id = vc.voice_log_customer.customer.id
              customer_name = vc.voice_log_customer.customer.customer_name rescue ""
            end
          end
        end
      
        car_no = ""
        if Aohs::MOD_CUST_CAR_ID and Aohs::MOD_CUSTOMER_INFO
          unless vc.voice_log_cars.empty?
            car_no = []
            car_id = []
            vc.voice_log_cars.each do |c|
              unless c.car_number.nil?
                car_no << format_car_id(c.car_number.car_no)
              end
            end
            car_no = car_no.join(",")
          end
        end
      
        vc_ng_count = 0
        vc_must_count = 0
        vc_book_count = 0
        transfer_call = nil
        is_found_transfer = false 
        
        #vc_c = vc.voice_log_counter
        if Aohs::MOD_CALL_TRANSFER 
	  vc_c = VoiceLogCounter.select("ngword_count,mustword_count,bookmark_count,transfer_call_count").where(:voice_log_id => vc.id).first
        else
	  vc_c = VoiceLogCounter.select("ngword_count,mustword_count,bookmark_count").where(:voice_log_id => vc.id).first
	end
        unless vc_c.nil?
          vc_ng_count = vc_c.ngword_count.to_i
          vc_must_count = vc_c.mustword_count.to_i
          vc_book_count = vc_c.bookmark_count.to_i
          
          if Aohs::MOD_CALL_TRANSFER
            if ctrl[:timeline_enabled] == true
              # not check because find all
            else
              is_found_transfer = vc.have_transfered_call?(vc_c.transfer_call_count.to_i)
            end
          end
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
  
end