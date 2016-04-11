module AmiReport
  
  def find_watch_managers
    if permission_by_name('tree_filter')
      gm = GroupManager.where(:user_id => current_user.id)
      unless gm.empty?
        managers = Manager.where(:id => gm.map { |m| m.manager_id })
      else
        managers = []
      end
      return managers
    else
      return nil
    end
  end
  
  def find_owner_groups

    groups = []
    
    if permission_by_name('tree_filter')

      grps_tmp1 = Group.select("id").where("leader_id = #{current_user.id}")        
      grps_tmp2 = GroupMember.select("group_id").where({:user_id => current_user.id})

      grps_tmp = []
      grps_tmp = grps_tmp.concat(grps_tmp1.map { |x| x.id }) unless grps_tmp1.empty?
      grps_tmp = grps_tmp.concat(grps_tmp2.map { |x| x.group_id }) unless grps_tmp2.empty?

      groups = grps_tmp.compact.uniq
    else
      groups = nil
    end

    return groups

  end

  def find_owner_agent

    groups = find_owner_groups

    agents = nil

    unless groups.nil?
      unless groups.empty?
        agents = Agent.where({:group_id => groups})
        
        # add leader
        leaders = Group.select('leader_id').where(:id => groups).all
        unless leaders.empty?
          agents = agents.concat(Manager.where(:id => leaders.map { |l| l.leader_id }).all)
        end
      end
    end

    return agents

  end

  def find_keyword_report
     #todo
  end

  def chek_report_period(period)

    case period
    when 'd','daily'
      return 'd'
    when 'w','weekly'
      return 'w'
    else 
      #'m','monthly'
      return 'm'
    end

  end

  def find_statistics_type_with_tabname(tname,rpfor="agent-report")
    
      tabname = tname
      statistics_type_id = 0
      rptitle = ""

      case rpfor
        when "agent-report"
          case tname
            when 'keywords'
                statistics_type_id = (StatisticsType.find_statistics_all(:target_model => "ResultKeyword",:by_agent => true,:value_type => ["sum:n","sum:m","sum:a"]).map { |s| s.id }).join(',')
                rptitle = "Keywords"
            when 'ng'
                statistics_type_id = StatisticsType.find_statistics(:target_model => "ResultKeyword",:by_agent => true,:value_type => "sum:n").id
                rptitle = "NG Words"
            when 'must'
                statistics_type_id = StatisticsType.find_statistics(:target_model => "ResultKeyword",:by_agent => true,:value_type => "sum:m").id
                rptitle = "Must Words"
            when 'action'
                statistics_type_id = StatisticsType.find_statistics(:target_model => "ResultKeyword",:by_agent => true,:value_type => "sum:a").id
                rptitle = "Action Words"
            when 'in'
                tabname = 'in'
                statistics_type_id = StatisticsType.find_statistics(:target_model => "VoiceLog",:by_agent => true,:value_type => "count:i").id
                rptitle = "Agent's Calls (Inbound)"    
            when 'out'
                tabname = 'out'
                statistics_type_id = StatisticsType.find_statistics(:target_model => "VoiceLog",:by_agent => true,:value_type => "count:o").id
                rptitle = "Agent's Calls (Outbound)"                    
            else #calls
                tabname = 'calls'
                statistics_type_id = StatisticsType.find_statistics(:target_model => "VoiceLog",:by_agent => true,:value_type => "count").id
                rptitle = "Agent's Calls"
          end
        when "keyword_report"
          statistics_type_id = StatisticsType.find_statistics(:target_model => "ResultKeyword",:by_agent => false,:value_type => "sum").id
          case tname
            when 'keywords'
                rptitle = "Keywords"
            when 'ng'
                rptitle = "NG Words"
            when 'must'
                rptitle = "Must Words"
            when 'action'
                rptitle = "Action Words"
            when 'group'
                rptitle = "Keyword's Group"
            else #k group
                tabname = 'keywords'
                rptitle = "Keywords"
          end
      end

      return tabname, statistics_type_id, rptitle
    
  end

  def find_statistics_date_rank(stdate,eddate,nm_day_display,period,at_day=0)

    if not stdate.nil? and not stdate.empty?
      start_date = Date.parse(stdate)
    else
      start_date = nil
    end
    if not eddate.nil? and not eddate.empty?
      end_date = Date.parse(eddate)
      if end_date > Date.today
         end_date = Date.today
      end
    else
      end_date = Date.today
    end

    if not start_date.nil? and not end_date.nil?
        if end_date < start_date
            temp = end_date
            end_date = start_date
            start_date = temp
        end
    end

    date_list = []
    case period
      when 'daily'

        if start_date.nil?
            start_date = end_date - nm_day_display
        else
            if (end_date - start_date) > nm_day_display
                end_date = start_date + nm_day_display
            else
                # ok in rank
            end
        end
        date_list = (start_date..end_date).to_a

    when 'weekly'
        if start_date.nil?
            nm_day_display.to_i.times do |a|
                date_list << (end_date.beginning_of_week + at_day ) - (7*a)
            end
            date_list = date_list.reverse
        else
            nm_day_display.to_i.times do |a|
                date_list << (start_date.beginning_of_week + at_day) + (7*a)
                if date_list.last > end_date
                    date_list.delete(date_list.last)
                    break
                end
            end
        end
    when 'monthly'
        if start_date.nil?
            tmp_date = end_date
            nm_day_display.to_i.times do |a|
                date_list << tmp_date.beginning_of_month + at_day
                tmp_date = tmp_date.beginning_of_month - 1
            end
            date_list = date_list.reverse!
        else
            tmp_date = start_date
            nm_day_display.to_i.times do |a|
                date_list << tmp_date.beginning_of_month + at_day
                tmp_date = tmp_date.end_of_month + 1
                if date_list.last > end_date
                    date_list.delete(date_list.last)
                    break
                end
            end
        end
    end

    return date_list

  end

  def find_result_date_rank(stdate,eddate,type)

    start_date = nil
    end_date = nil

    if stdate.is_a?(String)
      stdate = Date.parse(stdate)
    end

    if eddate.is_a?(String)
      eddate = Date.parse(eddate)
    else
      if eddate.nil? or eddate.empty?
        eddate = Date.today
      end
    end

    case type
      when 'daily'
        start_date = stdate
        end_date = start_date
      when 'weekly'
        begin_of_weekly = $CF.get('client.aohs_web.beginning_of_week')
        begin_of_weekly = Aohs::DAYS_OF_THE_WEEK.index("#{begin_of_weekly}").to_i
        start_date = stdate.beginning_of_week + begin_of_weekly
        end_date = start_date + 7 - 1 #stdate.end_of_week + begin_of_weekly - 1
      when 'monthly'
        begin_of_month = $CF.get('client.aohs_web.beginning_of_month')
        start_date = stdate.beginning_of_month + begin_of_month - 1
        end_date = stdate.end_of_month + begin_of_month - 1
      else
        start_date = stdate
        end_date = eddate
    end

    start_date = start_date.strftime("%Y-%m-%d 00:00:00")
    if end_date > Date.today
      end_date = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    else
      end_date = end_date.strftime("%Y-%m-%d 23:59:59")
    end

    return start_date, end_date

  end
  
  def find_keyword_report_with_agent(sc={})

     agents = [] #find_owner_agent

     sql_vc = "select v.agent_id,v.id from #{VoiceLogTemp.table_name} v "
     sql_vc << "where v.start_time between '#{sc[:st_date]}' and '#{sc[:ed_date]}' " unless sc[:st_date].nil?
     sql_vc << "and v.agent_id in (#{agents.map { |a| a.id }.join(',')}) " unless agents.blank?       
       
     sql0 = "(select v.agent_id,v.id as voice_log_id,count(r.id) as words_count,1 as result " 
     sql0 << "from (#{sql_vc}) v join result_keywords r on v.id = r.voice_log_id "
     sql0 << "where r.edit_status is null "
     sql0 << "and r.keyword_id in (#{sc[:keywords].join(',')}) " unless sc[:keywords].empty?     
     sql0 << "group by v.agent_id, v.id) "
    
     sql1 = "(select v.agent_id,v.id as voice_log_id,count(r.id) as word_count, 2 as result "
     sql1 << "from ((#{sql_vc})) v join edit_keywords r on v.id = r.voice_log_id "
     sql1 << "where r.edit_status in ('e','n') "
     sql1 << "and r.keyword_id in (#{sc[:keywords].join(',')}) " unless sc[:keywords].empty?         
     sql1 << "group by v.agent_id, v.id) "
     
     sql2 = "(#{sql0} union #{sql1})"
     
     sql = ""
     sum_sql = ""
     if sc[:group] == 'agent'
        sql = "select r.agent_id as id,u.role_id,u.display_name,u.group_id,g.name as group_name, count(r.voice_log_id) as calls_count,sum(r.words_count) as words_count "
        sql << "from #{sql2} r left join users u on u.id = r.agent_id left join groups g on u.group_id = g.id "
        sql << "group by r.agent_id "
        sql << "order by #{sc[:order]} "
        
        sum_sql = "select sum(r.calls_count) as calls_count, sum(r.words_count) as words_count from (#{sql}) r"
     else
       sql = "select if((u.group_id is null),0,u.group_id) as id,r.agent_id, count(r.voice_log_id) as calls_count,sum(r.words_count) as words_count "
       sql << "from #{sql2} r left join users u on u.id = r.agent_id "
       sql << "group by r.agent_id,u.group_id " 
       sql << "order by #{sc[:order]} "
        
       sql = "select r.id, g.name as group_name, count(r.agent_id) as agents_count, sum(r.calls_count) as calls_count, sum(r.words_count) as words_count from (#{sql}) r left join groups g on r.id = g.id group by r.id"  
        
       sum_sql = "select sum(r.calls_count) as calls_count, sum(r.words_count) as words_count from (#{sql}) r"   
     end

     result = []
     if sc[:show_all]
       result = VoiceLogTemp.find_by_sql(sql)
     else
       result = VoiceLogTemp.paginate_by_sql(sql,:page => sc[:page],:perpage => sc[:perpage])
     end

     summary = VoiceLogTemp.find_by_sql(sum_sql).first
     summary = {:calls_count => summary.calls_count, :words_count => summary.words_count}       
     
     return result, summary      

  end

  def voice_logs_default_filters
	
	conditions = []
	
	v = VoiceLogTemp.table_name
	if Aohs::VFILTER_DURATION_MIN.to_i > 0
		conditions << "#{v}.duration >= #{Aohs::VFILTER_DURATION_MIN.to_i}"
	end
	
	return conditions
	
  end
  
  def find_report_today(opt={})

    result = { :all => nil , :my => nil, :my_all => nil }
      
    select_date = Time.new.strftime("%Y-%m-%d")
    ##select_date = "2011-07-01"
    
    vl = VoiceLogTemp.table_name
    vc = VoiceLogCounter.table_name
    
    start_time = "#{select_date} 00:00:00"
    end_time = "#{select_date} 23:59:59"
    
    filt_cond = voice_logs_default_filters
    
    selects_sum_by_calls = "COUNT(#{vl}.id) as calls,SUM(IF(call_direction='i',1,0)) as inbound, SUM(IF(call_direction='o',1,0)) as outbound, SUM(#{vl}.duration) as duration, SUM(#{vc}.ngword_count) as ngwords, SUM(#{vc}.mustword_count) as mustwords"
    
    if true
    
      st_tmp = VoiceLogTemp.select(selects_sum_by_calls).joins("left join #{vc} on #{vl}.id = #{vc}.voice_log_id").where("#{vl}.start_time BETWEEN '#{start_time}' and '#{end_time}'")
      st_tmp = st_tmp.where(filt_cond) unless filt_cond.empty?
      st_tmp = st_tmp.first
      
      sql1 = " SELECT IFNULL(#{vl}.agent_id,0) as agent_id,COUNT(#{vl}.id) as calls,SUM(IF(#{vl}.call_direction='i',1,0)) as inbound,SUM(IF(#{vl}.call_direction='o',1,0)) as outbound, SUM(#{vl}.duration) as duration, SUM(#{vc}.ngword_count) as ngword, SUM(#{vc}.mustword_count) as mustword "
      sql1 << " FROM #{vl} LEFT JOIN #{vc} ON #{vl}.id = #{vc}.voice_log_id "
      sql1 << " WHERE #{vl}.start_time BETWEEN '#{start_time}' AND '#{end_time}' "
      sql1 << " AND #{filt_cond.join(' AND ')} " unless filt_cond.empty?
      sql1 << " GROUP BY #{vl}.agent_id " 
      
      sql1 = " SELECT agent_id,SUM(calls) as calls,SUM(inbound) as inbound,SUM(outbound) as outbound, SUM(duration) as duration, SUM(ngword) as ngword, SUM(mustword) as mustword FROM (#{sql1}) tbl GROUP BY agent_id "
      
      sql0 = " SELECT COUNT(agent_id) as agents, AVG(calls) as calls,AVG(inbound) as inbound, AVG(outbound) as outbound, AVG(duration) as duration, AVG(ngword) as ngword, AVG(mustword) as mustword "
      sql0 << " FROM (#{sql1}) tbl "
    
      st_tmp2 = VoiceLogTemp.find_by_sql(sql0).first  
      
      rs_tmp = {:agents => 0, :calls => 0, :duration => 0, :ngwords => 0, :mustwords => 0}
      
      unless st_tmp.nil?
        rs_tmp = {
            :agents => st_tmp2.agents.to_i, 
            :calls => st_tmp.calls.to_i,
            :inbound => st_tmp.inbound.to_i,
            :outbound => st_tmp.outbound.to_i,
            :duration => st_tmp.duration.to_i, 
            :ngwords => st_tmp.ngwords.to_i,
            :mustwords => st_tmp.mustwords.to_i,
            :avg_agent => (st_tmp2.agents.to_i <= 0 ? 0 : 1),
            :avg_call => st_tmp2.calls.to_f.round,
            :avg_inbound => st_tmp2.inbound.to_f.round,
            :avg_outbound => st_tmp2.outbound.to_f.round,
            :avg_duration => st_tmp2.duration.to_f,
            :avg_ngword => st_tmp2.ngword.to_f,
            :avg_mustword => st_tmp2.mustword.to_f
        }
      end
       
      result[:all] = rs_tmp
                       
    end
    
    if opt[:me] == true
      me = current_user.id      
      st_tmp = VoiceLogTemp.select(selects_sum_by_calls).where("#{vl}.start_time BETWEEN '#{start_time}' and '#{end_time}' and #{vl}.agent_id = #{me}").joins("left join #{vc} on #{vl}.id = #{vc}.voice_log_id")
      st_tmp = st_tmp.where(filt_cond) unless filt_cond.empty?
      st_tmp = st_tmp.first
      
      rs_tmp = {:agents => 0, :calls => 0, :duration => 0, :ngwords => 0, :mustwords => 0}
      unless st_tmp.nil?
        rs_tmp = {
            :agents => 1, 
            :calls => st_tmp.calls.to_i,
            :inbound => st_tmp.inbound.to_i,
            :outbound => st_tmp.outbound.to_i,
            :duration => st_tmp.duration.to_i, 
            :ngwords => st_tmp.ngwords.to_i,
            :mustwords => st_tmp.mustwords.to_i
        }
      end
      result[:me] = rs_tmp
    end
        
    if opt[:with_agent] == true
      
       my_agents = find_owner_agent
       unless my_agents.blank?
         my_agents = (my_agents.map{ |a| "#{a.id}" }).uniq
       else
         my_agents = [-1] # lowest value
       end
       
       st_tmp = VoiceLogTemp.select(selects_sum_by_calls).where("#{vl}.start_time BETWEEN '#{start_time}' and '#{end_time}' and #{vl}.agent_id IN (#{my_agents.join(',')})").joins("left join #{vc} on #{vl}.id = #{vc}.voice_log_id")
       st_tmp = st_tmp.where(filt_cond) unless filt_cond.empty?
       st_tmp = st_tmp.first
      
       sql1 = " SELECT (#{vl}.agent_id) as agent_id,COUNT(#{vl}.id) as calls, SUM(IF(#{vl}.call_direction='i',1,0)) as inbound,SUM(IF(#{vl}.call_direction='o',1,0)) as outbound, SUM(#{vl}.duration) as duration, SUM(#{vc}.ngword_count) as ngword, SUM(#{vc}.mustword_count) as mustword "
       sql1 << " FROM #{vl} LEFT JOIN #{vc} ON #{vl}.id = #{vc}.voice_log_id "
       sql1 << " WHERE #{vl}.start_time BETWEEN '#{start_time}' AND '#{end_time}' AND #{vl}.agent_id IN (#{my_agents.join(',')})"
       sql1 << " AND #{filt_cond.join(' AND ')} " unless filt_cond.empty?
       sql1 << " GROUP BY #{vl}.agent_id "
       sql0 = " SELECT COUNT(agent_id) as agents, AVG(calls) as calls,AVG(calls) as calls, AVG(inbound) as inbound, AVG(outbound) as outbound, AVG(duration) as duration, AVG(ngword) as ngword, AVG(mustword) as mustword "
       sql0 << " FROM (#{sql1}) tbl "
        
       st_tmp2 = VoiceLogTemp.find_by_sql(sql0).first                                   
       
       rs_tmp = {:agents => 0, :calls => 0, :duration => 0, :ngwords => 0, :mustwords => 0}
         
       unless st_tmp.nil?
        rs_tmp = {
            :agents => st_tmp2.agents.to_i, 
            :calls => st_tmp.calls.to_i, 
            :duration => st_tmp.duration.to_i,
            :inbound => st_tmp.inbound.to_i,
            :outbound => st_tmp.outbound.to_i, 
            :ngwords => st_tmp.ngwords.to_i,
            :mustwords => st_tmp.mustwords.to_i,
            :avg_agent => 1,
            :avg_call => st_tmp2.calls.to_f.round,
            :avg_inbound => st_tmp2.inbound.to_f.round,
            :avg_outbound => st_tmp2.outbound.to_f.round,
            :avg_duration => st_tmp2.duration.to_f,
            :avg_ngword => st_tmp2.ngword.to_f,
            :avg_mustword => st_tmp2.mustword.to_f
        }
       end
              
       result[:my] = rs_tmp
       
       rs_tmp = {
            :agents => (result[:all][:agents].to_f <= 0 ? "0.00" : (result[:my][:agents].to_f/result[:all][:agents].to_f) * 100),
            :calls => (result[:all][:calls].to_f <= 0 ? "0.00" : (result[:my][:calls].to_f/result[:all][:calls].to_f) * 100),
            :inbound => (result[:all][:inbound].to_f <= 0 ? "0.00" : (result[:my][:inbound].to_f/result[:all][:inbound].to_f) * 100),  
            :outbound => (result[:all][:outbound].to_f <= 0 ? "0.00" : (result[:my][:outbound].to_f/result[:all][:outbound].to_f) * 100),     
            :duration => (result[:all][:duration].to_f <= 0 ? "0.00" : (result[:my][:duration].to_f/result[:all][:duration].to_f) * 100),
            :ngwords => (result[:all][:ngwords].to_f <= 0 ? "0.00" : (result[:my][:ngwords].to_f/result[:all][:ngwords].to_f) * 100),
            :mustwords => (result[:all][:mustwords].to_f <= 0 ? "0.00" : (result[:my][:mustwords].to_f/result[:all][:mustwords].to_f) * 100) 
       }

       result[:my_all] = rs_tmp     
    end
  
    return result

  end
  
end