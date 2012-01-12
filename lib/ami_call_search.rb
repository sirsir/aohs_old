
module AmiCallSearch

  def set_current_user_for_call_search(user_id)

    @app_user = nil
    
    if not user_id.nil? and user_id.to_i > 0
      @app_user = User.find(user_id)
    else
      @app_user = User.find(current_user.id)
    end

  end
 
  def voice_log_cols

     return ["#","Date/Time","Duration","Caller Number","Dialed Number","Extention","Agent","Customer","Direction","NG Word","Must Word","Bookmark"]

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
        dt_cond = nil
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
           edtime = Time.parse(ed_time).strftime("%H:%M:59")
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
      
      grps_tmp1 = Group.find(:all,
                           :select => 'id',
                           :conditions => "leader_id = #{@app_user.id}")

      grps_tmp2 = GroupMember.find(:all,
                                 :select => 'group_id',
                                 :conditions => {:user_id => @app_user.id})
      grps_tmp = []
      grps_tmp = grps_tmp.concat(grps_tmp1.map { |x| x.id }) unless grps_tmp1.empty?
      grps_tmp = grps_tmp.concat(grps_tmp2.map { |x| x.group_id }) unless grps_tmp2.empty?

      unless grps_tmp.empty?
        agents = Agent.find(:all,
                          :select => 'id',
                          :conditions => "group_id in (#{grps_tmp.join(",")})")
        unless agents.empty?
          agents = agents.map { |y| y.id }
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

    mgs = GroupManager.find(:all,:conditions => {:user_id => @app_user.id})
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
  
  def find_agent_by_group(groups_id)

    agents = []
 
    unless groups_id.empty?
       groups_id = groups_id.map {|g| g.to_i}
       if permission_by_name('tree_filter')
           grps_tmp1 = Group.find(:all,
                                 :select => 'id',
                                 :conditions => "id in (#{groups_id.join(",")}) and leader_id = #{@app_user.id}")
           
           grps_tmp2 = GroupMember.find(:all,
                                        :select => 'group_id',
                                        :conditions => {:user_id => @app_user.id})
           
           grps_tmp = []
           grps_tmp = grps_tmp.concat(grps_tmp1.map { |x| x.id.to_i }) unless grps_tmp1.empty?
           grps_tmp = grps_tmp.concat(grps_tmp2.map { |x| x.group_id.to_i }) unless grps_tmp2.empty?

           fgroups = groups_id & grps_tmp

           unless fgroups.empty?

             agents = Agent.find(:all,
                               :select => 'id',
                               :conditions => "group_id in (#{fgroups.join(",")})")
             unless agents.empty?
              agents = agents.map { |y| y.id }
             end
           end
       else
             agents = Agent.find(:all,
                               :select => 'id',
                               :conditions => "group_id in (#{groups_id.join(",")})")
             unless agents.empty?
              agents = agents.map { |y| y.id }
             end
       end
    else
           grps_tmp = Group.find(:all,
                                 :select => 'id',
                                 :conditions => "leader_id = #{@app_user.id}")
           unless grps_tmp.empty?
             grps_tmp = grps_tmp.map { |x| x.id }
             agents = Agent.find(:all,
                               :select => 'id',
                               :conditions => "group_id in (#{grps_tmp.join(",")})")
             unless agents.empty?
              agents = agents.map { |y| y.id }
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
      groups_id = GroupCategorization.find(:all,
                                           :select => 'group_id,count(id) as rec_count',
                                           :conditions => "group_category_id in (#{cates_tmp.join(",")})",
                                           :group => 'group_id')
      
      groups_id_tmp = (groups_id.map { |x| x.rec_count.to_i == cates_tmp.length ? x.group_id.to_i : nil }).compact
  
      agents = find_agent_by_group(groups_id_tmp)
    end

    return agents

  end

  def find_agent_calls(sc={})

    vl_tbl_name = VoiceLogTemp.table_name
    set_current_user_for_call_search(sc[:ctrl][:user_id])
    
    voice_logs = []
    summary = {}
    page_info = {}
    
    # -- voice_logs data --
	
    sc[:conditions] = sc[:conditions].compact
    sc[:order] = sc[:order].compact.join(',') unless sc[:order].blank? 
      
    # for search
    joins = []
    includes = [:voice_log_counter,:user]
    # for count and summary 
    joins2 = [:voice_log_counter]      
    includes2 = []
        
    sc[:conditions].each do |cond|
      if cond =~ /^result_keywords/
        includes << :result_keywords
        joins2 << :result_keywords
        break
      end
    end
    
    voice_logs = VoiceLogTemp.find(:all,
                               :include => includes,
                               :joins => joins,
                               :conditions => sc[:conditions].join(' and '),
                               :limit => sc[:limit],
                               :offset => sc[:offset],
                               :order => sc[:order])
        
    # -- summary data --

    summary = {:sum_dura => 0, :sum_ng => 0, :sum_mu => 0,:c_in => 0,:c_out => 0,:c_oth => 0}
    if not voice_logs.blank? and sc[:summary] == true

      v = VoiceLogTemp.table_name
      c = VoiceLogCounter.table_name
      
      select_sql = ""
      select_sql << " sum(v.duration) as duration,sum(v.ngword_count) as ng_word, sum(v.mustword_count) as mu_word, "
      select_sql << " sum(IF(v.call_direction = 'i',1,0)) as call_in, "
      select_sql << " sum(IF(v.call_direction = 'o',1,0)) as call_out, "
      select_sql << " sum(IF((v.call_direction in ('e','u')),1,0)) as call_oth "
      
      sql = ""      
      sql << " SELECT #{v}.id,#{v}.call_direction,#{v}.duration,#{c}.ngword_count,#{c}.mustword_count "
      sql << " FROM (#{v} LEFT JOIN #{c} ON #{v}.id = #{c}.voice_log_id) "
      if joins2.include?(:result_keywords)
        sql << " LEFT JOIN result_keywords on #{v}.id = result_keywords.voice_log_id "
      end
      sql << " WHERE #{sc[:conditions].join(' and ')} " unless sc[:conditions].empty?
      sql << " GROUP BY #{v}.id "
      
      sql = " SELECT #{select_sql} FROM (#{sql}) v"
      
      result = VoiceLogTemp.find_by_sql(sql).first
      
      unless result.blank?
        summary[:sum_dura] = format_sec(result.duration.to_i)
        summary[:sum_ng] = number_with_delimiter(result.ng_word.to_i)
        summary[:sum_mu] = number_with_delimiter(result.mu_word.to_i)
        summary[:c_in] = number_with_delimiter(result.call_in.to_i)
        summary[:c_out] = number_with_delimiter(result.call_out.to_i)
        summary[:c_oth] = number_with_delimiter(result.call_oth.to_i)
      end

    end

    # page info

    if not sc[:page] == false

      record_count = 0
      unless voice_logs.blank?

        v = VoiceLogTemp.table_name
        c = VoiceLogCounter.table_name        

        sql = ""      
        sql << " SELECT #{v}.id"
        sql << " FROM (#{v} LEFT JOIN #{c} ON #{v}.id = #{c}.voice_log_id) "
        if joins2.include?(:result_keywords)
          sql << " LEFT JOIN result_keywords on #{v}.id = result_keywords.voice_log_id "
        end
        sql << " WHERE #{sc[:conditions].join(' and ')} " unless sc[:conditions].empty?
        sql << " GROUP BY #{v}.id "
                        
        sql = "SELECT COUNT(id) as rec_count FROM (#{sql}) v"

        record_count = VoiceLogTemp.find_by_sql(sql).first.rec_count
        
      end

      page = sc[:page]
      total_page = 0
      total_page = ((record_count).to_f / sc[:perpage]).ceil
      page = 0 if total_page == 0
      tl_start_date = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" if total_page == 0
      sc[:page] = page

      page_info = {
        :page => 'true',
        :total_page => total_page,
        :current_page => page,
        :rec_count => record_count,
        :tl_stdate => tl_start_date.nil? ? "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" : tl_start_date
     }
      
    else
      page_info[:page] = 'true'
      page_info[:records_count] = 0
      page_info[:tl_stdate] = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z"
    end

    agents = find_owner_agents
	
    if sc[:limit_display_users] == true
      voice_logs = convert_voice_logs_info(voice_logs,agents,sc)
    else
      voice_logs = convert_voice_logs_info(voice_logs,false,sc)
    end
     
	  sc = nil
	
    return voice_logs,summary, page_info, agents

  end

  def find_customer_calls(sc={})

    sc[:limit_display_users] = true
    
    voice_logs, summary, page_info, agents = find_agent_calls(sc)

    return voice_logs,summary, page_info, agents

  end

  def find_call_with_tags(sc={})

    vl_tbl_name = VoiceLogTemp.table_name
    
    set_current_user_for_call_search(sc[:ctrl][:user_id])
    skip_search = false
    
    voice_logs = []
    summary = {}
    page_info = {}
    conditions = []
        
    key_tags = []
      
    if not sc[:group_tag_id].empty? and sc[:group_tag_id].to_i > 0
      
      tags = TagGroup.find(:all,:conditions => {:id => sc[:group_tag_id].to_i})
      unless tags.empty?
        tags.each do |t|
           if t.tags.length > 0
             key_tags.concat((t.tags.map {|t2| t2.name }))
           end
        end
      end         
    elsif not sc[:tag_id].empty? and sc[:tag_id].to_i > 0
      
      tag = Tag.find(:first,:conditions => {:id => sc[:tag_id].to_i})
      unless tag.nil?
        key_tags << tag.name
      end
      
    elsif not sc[:tags].empty?
      key_tags << "#{sc[:tags].strip}%"
    else
      key_tags << "%"
    end
 
    agents = find_owner_agents
    
    unless agents.nil?
      unless agents.empty?
        conditions << "(#{vl_tbl_name}.agent_id in (#{agents.join(',')}) or #{vl_tbl_name}.agent_id is null or #{vl_tbl_name}.agent_id = 0)"
      end
    end
    
    ctags = key_tags
    unless ctags.empty?
      ctags = "(#{(ctags.map { |t| "tags.name like '#{t}'"}).join(" or ")})"
    else
      ctags = []
    end

    new_cond = []
    if conditions.empty?
      new_cond << ctags
    else
      new_cond << Array.new(conditions).concat([ctags])
    end

    voice_logs = []
    if not skip_search

      voice_logs = VoiceLogTemp.find(:all,
                               :joins => [:taggings,:tags],
                               :include => [:user,:voice_log_counter],
                               :conditions => new_cond.join(" and "),
                               :limit => sc[:limit],
                               :offset => sc[:offset],
                               :group => "#{vl_tbl_name}.id",
                               :order => sc[:order].join(','))

      unless voice_logs.empty?
        tagsc = key_tags.map { |k| "tags.name like '#{k}'" }
        tags = Tag.find(:all,:conditions => "(#{tagsc.join(' or ')})")
        tags_id = tags.map {|t| t.id }
        conditions << "taggings.tag_id in (#{tags_id.join(',')})"
      end

    end
    
    summary = {:sum_dura => 0, :sum_ng => 0, :sum_mu => 0,:c_in => 0,:c_out => 0,:c_oth => 0}

    if sc[:summary] == true and not voice_logs.empty?

      select_sql = ""
      select_sql << " sum(#{vl_tbl_name}.duration) as duration,sum(#{vl_tbl_name}.ngword_count) as ng_word, sum(#{vl_tbl_name}.mustword_count) as mu_word, "
      select_sql << " sum(IF(#{vl_tbl_name}.call_direction like 'i',1,0)) as call_in, "
      select_sql << " sum(IF(#{vl_tbl_name}.call_direction like 'o',1,0)) as call_out, "
      select_sql << " sum(IF((#{vl_tbl_name}.call_direction like 'e' or #{vl_tbl_name}.call_direction like 'u'),1,0)) as call_oth "

      result = nil
      
      #result = VoiceLogTemp.find(
      #      :first,
      #      :select => select_sql,
      #      :joins => [:voice_log_counter,:taggings],
      #      :conditions => conditions.join(' and '))

      str_cond = ""
      str_cond = "WHERE #{conditions.join(' and ')}" unless conditions.empty?
      
      result = VoiceLogTemp.find_by_sql("SELECT #{select_sql} FROM (SELECT #{vl_tbl_name}.id,#{vl_tbl_name}.duration,#{vl_tbl_name}.call_direction,voice_log_counters.ngword_count,voice_log_counters.mustword_count FROM (#{vl_tbl_name} JOIN voice_log_counters on #{vl_tbl_name}.id = voice_log_counters.voice_log_id) join taggings ON #{vl_tbl_name}.id = taggings.taggable_id #{str_cond} GROUP BY #{vl_tbl_name}.id) #{vl_tbl_name} ")
      result = result.first

      unless result.nil?
        summary[:sum_dura] = format_sec(result.duration.to_i)
        summary[:sum_ng] = number_with_delimiter(result.ng_word)
        summary[:sum_mu] = number_with_delimiter(result.mu_word)
        summary[:c_in] = number_with_delimiter(result.call_in)
        summary[:c_out] = number_with_delimiter(result.call_out)
        summary[:c_oth] = number_with_delimiter(result.call_oth)
      end

    end

    # page info

    if (not sc[:page] == false) and (not skip_search) and (not voice_logs.empty?)
      page = sc[:page]
      
      record_count = VoiceLogTemp.count(
              :id,
              :include => [:taggings],
              :conditions => conditions.join(' and '))

      total_page = 0
      total_page = ((record_count).to_f / sc[:perpage]).ceil
      page = 0 if total_page == 0
      tl_start_date = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" if total_page == 0

      sc[:page] = page
      page_info = {
        :page => 'true',
        :total_page => total_page,
        :current_page => page,
        :rec_count => record_count,
        :tl_stdate => tl_start_date.nil? ? "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z" : tl_start_date
      }

    else
      page_info[:page] = 'true'
      page_info[:rec_count] = 0
      page_info[:current_page] = 0  
      page_info[:tl_stdate] = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}Z"
      page_info[:total_page] = 0   
    end

    agents = nil #find_owner_agents

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

    u_display_mode = AmiConfig.get('client.aohs_web.reportUserNameDisplay').to_i

    unless voice_logs.blank?

      if sc[:page].blank? or sc[:page].to_i <= 0
        sc[:page] = 1
      end
       
	  start_row = sc[:perpage] * (sc[:page].to_i-1)
		
      voice_logs.each_with_index do |vc,i|
    
        datetime = nil
        unless vc.start_time.nil?
          if vc.start_time.is_a?(String)
            datetime = Time.parse(vc.start_time)
          else
            datetime = vc.start_time
          end
        else
          STDERR.puts "voice_logs datetime not found"
        end

        tags = "No tag."
        if ctrl[:tag_enabled] == true
          tags = vc.tag_list
          if tags.blank?
            tags = "No tag."
          end
        end

        is_open = true
        agent_name = "UnknownAgent"
        if (vc.agent_id.to_i > 0) and (not vc.user.nil?)
          agent_name = (u_display_mode == 0 ? vc.user.login : vc.user.display_name)
          if not agents == false
            is_open = call_open?(vc.agent_id,agents)
          end
        end

        customer_name = ""
        #unless vc.voice_log_customer.nil?
        # unless vc.voice_log_customer.customer.nil?
        #    customer_name = vc.voice_log_customer.customer.customer_name rescue "-"
        #  end
        #end

        vc_ng_count = 0
        vc_must_count = 0
        vc_book_count = 0
        unless vc.voice_log_counter.nil?
          vc_ng_count = vc.voice_log_counter.ngword_count.to_i
          vc_must_count = vc.voice_log_counter.mustword_count.to_i
          vc_book_count = vc.voice_log_counter.bookmark_count.to_i
        end

        transfer_call = nil
        #unless true
        #  transfer_call = nil
        #end

        xduration = 0
        if vc.duration.nil?
          xduration = 0
        else
          xduration = vc.duration.to_i
        end

        xextension = ""
        if not vc.extension.nil?
           xextension = vc.extension
        end
        
        new_voice_logs << {
            :no => (i+1)+start_row,
            :id => vc.id,
            :sdate => "#{datetime.strftime('%Y-%m-%d %H:%M:%S')}",
            :edate => "#{(datetime + xduration).strftime('%Y-%m-%d %H:%M:%S')}",
            :duration => "#{format_sec(xduration)}",
            :dmin => (xduration/60),
            :ani => vc.ani,
            :dnis => vc.dnis,
            :ext => xextension,
            :agent => agent_name,
            :cust => customer_name,
            :cd => vc.call_direction_name,
            :cd_c => vc.call_direction,
            :ngc => vc_ng_count,
            :mustc => vc_must_count,
            :bookc => vc_book_count,
            :tags => tags,
            :path => audio_src_path(vc.disposition),
            :open => is_open,
            :dev => vc.device_id,
            :trfcall => transfer_call
        }
      end
    end
	
    voice_logs = nil
    return new_voice_logs

  end
  
end