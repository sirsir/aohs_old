class TimelineController < ApplicationController

   require 'cgi'

   include AmiTimeline
   include AmiCallSearch

   def timeline_calls

     session[:user_id] = params[:user_id].to_i
             
     tlx = params[:tl]

     tl_source = ""
     case tlx
       when "agcalls"
        tl_source = timeline_agent_calls
       when "cucalls"
        tl_source = timeline_customer_calls
     end

     send_data(tl_source,{:type => 'text/plain',:disposition => 'attachment',:filename => 'tlsource.txt'})

   end

   def timeline_agent_calls

    ctrl = {:show_all => true, :timeline_enabled => true, :tag_enabled => false, :user_id => params[:user_id].to_i }

    vl_tbl_name = VoiceLogTemp.table_name
    tl_source = ""

    conditions = []
    skip_search = false

    # === search conditions ===

    # agents conditions
    if params.has_key?(:keys) and not params[:keys].empty?

      begin
        if not params[:user_id].empty?
          set_current_user_for_call_search(params[:user_id].to_i)
        end
      rescue => e
        skip_search = true
      end

      keys = []
      keys = CGI::unescape(params[:keys]).split("__")
      agents = []
      keys.each do |key|
        k = key.split("=")
        case k[0]
          when /^(cate)/
            agents = find_agent_by_cate(k[1])
          when /^(groups)/
            if k[1] != "none"
              groups_id = k[1].split(',')
              agents.concat(find_agent_by_group(groups_id))
            end
          when /^(agents)/
            if k[1] != "none"
              agents.concat(find_agent_by_agents(k[1]))
            end
          when /^(agent)/
            agents = find_agent_by_agent(k[1])
          when /^(all)/
            agents = find_agent_by_group([])
        end
      end
      agents = nil if agents.empty?

      if agents.nil?
        if permission_by_name('tree_filter')
          show_as_unk = ($CF.get('client.aohs_web.displayDeletedAgentAsUnk').to_i == 1)
          if show_as_unk
            agents = User.deleted.map { |a| a.id }
          else 
            agents = []
          end
          agents << 0
          conditions << "(#{vl_tbl_name}.agent_id is null or #{vl_tbl_name}.agent_id in (#{agents.join(',')}))"
        end
      else
        if agents.empty?
          skip_search = true
        else
          conditions << "#{vl_tbl_name}.agent_id in (#{agents.join(',')})"
        end
      end

    else
      skip_search = true
    end

    # call date / time
    conditions << retrive_datetime_condition(params[:periods],params[:stdate],params[:sttime],params[:eddate],params[:edtime])

    # extension
    if params.has_key?(:ext) and not params[:ext].empty?
      conditions << "#{vl_tbl_name}.extension like '#{params[:ext]}%'"
    end

    #ani
    if params.has_key?(:caller) and not params[:caller].empty?
      conditions << "#{vl_tbl_name}.ani like '#{params[:caller].strip}%'"
    end

    #dnis
    if params.has_key?(:dialed) and not params[:dialed].empty?
      conditions << "#{vl_tbl_name}.dnis like '#{params[:dialed].strip}%'"
    end

    # call direction
    call_directions = []
    if params.has_key?(:calld) and not params[:calld].empty?
      cd_ary = CGI::unescape(params[:calld]).split('')
      cd_ary.to_s.each_char do |c|
        call_directions << c
        call_directions.concat(['u','e']) if c == 'e'     
      end
      call_directions = [] if call_directions.uniq.sort == ['i','o','u','e'].sort 
      call_directions = call_directions.uniq.map { |c| "'#{c}'"}
    else
      skip_search = true
    end
    
    unless call_directions.empty?
      case call_directions.length
      when 1
        conditions << "#{vl_tbl_name}.call_direction = '#{call_directions.first.gsub('\'','')}'"
      else
        conditions << "#{vl_tbl_name}.call_direction in (#{call_directions.join(',')})"
      end    
    end
  
    # call duration
    conditions << retrive_duration_conditions(params[:stdur],params[:eddur])

    if params.has_key?(:keyword) and not params[:keyword].empty?
      knames = CGI::unescape(params[:keyword]).split(" ")
      keywords = Keyword.find(:all,:select => 'id',:conditions => (knames.map { |k| "name like '%#{k}%'" }).join(" or ") )
      if keywords.empty?
        skip_search = true
      else
        keywords = (keywords.map { |k| k.id }).join(',')
        conditions << "#{ResultKeyword.table_name}.keyword_id in (#{keywords})"
      end
    end

    # ==========================================================================

    $NM_MAX_TL = $CF.get('client.aohs_web.number_of_max_timeline').to_i
    start_row = 0

    orders = ['users.login asc',"#{vl_tbl_name}.start_time asc"]
  
    if $NM_MAX_TL <= 0
      offset = 0
      limit = false
      page = false
    else
      page = 1
      offset = start_row
      limit = $NM_MAX_TL
    end

    unless skip_search
        voice_logs, summary, page_info, agents = find_agent_calls({
                :select => [],
                :conditions => conditions,
                :order => orders,
                :offset => offset,
                :limit => limit,
                :page => page,
                :perpage => $NM_MAX_TL,
                :summary => true,
                :ctrl => ctrl })
         
    end

    tl_data = {}
    unless voice_logs.blank?

      voice_logs.each do |vl|

        start_date = vl[:sdate]
        end_date = vl[:edate]

        agent_name = vl[:agent]
        if tl_data[agent_name].nil?
            tl_data[agent_name] = {}
            tl_data[agent_name][:min] = start_date
            tl_data[agent_name][:max] = end_date
            tl_data[agent_name][:b] = []
        end
		
		if (vl[:cd] == 'u')
			vl[:cd] = 'e'
		end
		
        tl_data[agent_name][:max] = end_date
        tl_data[agent_name][:b] << "[#{vl[:cd_c]},#{start_date},#{end_date}]"

      end
	  
	  voice_logs = nil
	  
    end

    tl_data2 = []
    tl_data.each_key do |key|
      rank = "[x,#{tl_data[key][:min]},#{tl_data[key][:max]}]"
      tl_data2 << "#{key}:[#{(tl_data[key][:b].insert(0,rank)).join(",")}]"
    end
    
    tl_data.clear

    return tl_data2.join(";")
     
   end

   def timeline_customer_calls

    ctrl = {:show_all => true, :timeline_enabled => true, :tag_enabled => false, :user_id => params[:user_id] }
    tl_source = ""
    vl_tbl_name = VoiceLogTemp.table_name
    skip_search = false
    conditions = []

    page = 1
    findby = ""

    customer_id = params[:customer_id].to_i

    phone_numbers = []

    if customer_id > 0
      customer = Customers.select({:id => customer_id}).first
      unless customer.blank?
        unless customer.customer_numbers.blank?
          customer.customer_numbers.each { |p| phone_numbers << p.number }
        end
      else
        skip_search = true
      end
    end

    if params.has_key?(:cust_phone) and not params[:cust_phone].empty?
      key_phone = (CGI::unescape(params[:cust_phone])).split(',').compact
      key_phone = key_phone.uniq
      phone_numbers = phone_numbers.concat(key_phone)
    end


    phone_numbers = phone_numbers.uniq
    unless phone_numbers.empty?
      ani_cond = phone_numbers.map { |p| "#{vl_tbl_name}.ani = '#{p}'"}
      dnis_cond = phone_numbers.map { |p| "#{vl_tbl_name}.dnis = '#{p}'"}
      conditions << "(#{ani_cond.concat(dnis_cond).join(' or ')})"
    else
      skip_search = true
    end

    conditions << retrive_datetime_condition(params[:dateCondition],params[:start_date],params[:start_time],params[:end_date],params[:end_time])

    #===========================================================================

    $NM_MAX_TL = $CF.get('client.aohs_web.number_of_max_timeline').to_i

    orders = ['users.login asc',"#{vl_tbl_name}.start_time asc"]

    start_row = 0
    records_count = 0
    offset = nil
    limit = nil
    
    if $NM_MAX_TL > 0
      page = 1
      offset = start_row
      limit = $NM_MAX_TL
    else
      page = false
      offset = false
      limit = false
    end

    find_summary = false

    voice_logs = []
    unless skip_search
      voice_logs,summary, page_info,agents = find_customer_calls({
                :select => [],
                :conditions => conditions,
                :order => orders,
                :offset => offset,
                :limit => limit,
                :page => page,
                :perpage => $NM_MAX_TL,
                :summary => find_summary,
                :ctrl => ctrl})
    end
    
    tl_data = {}

    unless voice_logs.blank?

      voice_logs.each do |vl|

        start_date = vl[:sdate]
        end_date = vl[:edate]

        agent_name = vl[:agent]
        if tl_data[agent_name].nil?
            tl_data[agent_name] = {}
            tl_data[agent_name][:min] = start_date
            tl_data[agent_name][:max] = end_date
            tl_data[agent_name][:b] = []
        end

		if (vl[:cd] == 'u')
			vl[:cd] = 'e'
		end
		
        tl_data[agent_name][:max] = end_date
        tl_data[agent_name][:b] << "[#{vl[:cd_c]},#{start_date},#{end_date}]"

      end
	  
	  voice_logs = nil
	  
    end

    tl_data2 = []
    tl_data.each_key do |key|
      rank = "[x,#{tl_data[key][:min]},#{tl_data[key][:max]}]"
      tl_data2 << "#{key}:[#{(tl_data[key][:b].insert(0,rank)).join(",")}]"
    end
    tl_data.clear
    
    return tl_data2.join(";")

   end
  
end
