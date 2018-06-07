module CallStatisticsReport
  class AgentCallSummary < CallReportBase
    
    def initialize(opts={})
      set_params opts
      set_option :report_name, "Agent Call Summary Report"
      set_option :show_average_call_per_day, true
      initial_report
      initial_header
      initial_footer
    end
    
    def initial_header
      row_cnt = @headers.length
      scols = selected_columns
      tcols = selected_summary_columns
      ucols = agent_info_columns
      gcols = group_info_columns
      xcols = [].concat(ucols).concat(gcols).concat(tcols)
      
      # row 1
      cols = []
      cols_r2 = []
      xcols.each do |cl|
        cols << new_element(cl[:display_name], 1, 2)
      end
      if defined? @dsel_range and (not @dsel_range.nil?)
        dmyhdr = dmy_header
        dmyhdr[:days].each do |d|
          cols << new_element(d[:full_label], scols.length, 1)
          scols.each do |c|
            cols_r2 << new_element(c[:display_name], 1, 1)
          end
        end
      end
      add_header(cols,0,0)
      
      # row 2
      cols = cols_r2
      add_header(cols,1,0)
    end
    
    def initial_footer
      @footer = {}  
    end
    
    def get_result
      return {
        headers: @headers,
        data: get_data,
        footer: @footer
      }
    end
    
    def to_xlsx
      return to_xlsx_file_default
    end
    
    private
    
    def get_data
      data = []
      summary_data = {}
      ulist = []
      
      if show_nodata_record?
        ulist, atlinf2 = get_full_list_agent
      end
      scols = selected_columns
      tcols = selected_summary_columns
      ucols = agent_info_columns
      gcols = group_info_columns
      
      result = select_sql(sql_data)
      altinf = get_list_groupinfo_from_atl
      
      result.each do |rs|
        rs["sad"] = rs["std"].to_i / rs["snc"].to_i rescue 0
        rs["sac"] = rs["snc"].to_i / rs["day_count"].to_i rescue 0
        summary_data["day_count"] = summary_data["day_count"].to_i + rs["day_count"].to_i
        summary_data["snc"] = summary_data["snc"].to_i + rs["snc"].to_i
        summary_data["std"] = summary_data["std"].to_i + rs["std"].to_i
        summary_data["sad"] = summary_data["std"] / summary_data["snc"] rescue 0
        summary_data["sac"] = summary_data["snc"] / summary_data["day_count"] rescue 0
        if rs["smd"].to_i > summary_data["smd"].to_i
          summary_data["smd"] = rs["smd"].to_i
        end
        @dsel_range.each_with_index do |dt,i|
          rs["ad#{i}"] = rs["td#{i}"].to_i / rs["nc#{i}"].to_i rescue 0
          summary_data["nc#{i}"] = summary_data["nc#{i}"].to_i + rs["nc#{i}"].to_i
          summary_data["td#{i}"] = summary_data["td#{i}"].to_i + rs["td#{i}"].to_i
          if rs["md#{i}"].to_i > summary_data["md#{i}"].to_i
            summary_data["md#{i}"] = rs["md#{i}"].to_i
          end
        end
      end
      
      result.each do |rs|
        d = []
        u = get_user_info(rs["agent_id"])
        g = altinf[rs["agent_id"].to_s] || {}
        u = u.merge(g)
        udel = ulist.delete(rs["agent_id"].to_s)
        ucols.each do |cl|
          d << u[cl[:name]]
        end
        gcols.each do |cl|
          d << u[cl[:name]]
        end
        tcols.each do |cl|
          if cl[:unit] == :duration
            d << duration_fmt(rs["s#{cl[:select_prefix]}"])
          else
            d << number_fmt(rs["s#{cl[:select_prefix]}"])
          end
        end
        if defined? @dsel_range and (not @dsel_range.nil?) 
          @dsel_range.each_with_index do |dt,i|
            scols.each do |cl|
              if cl[:unit] == :duration
                d << duration_fmt(rs["#{cl[:select_prefix]}#{i}"])
              else
                d << number_fmt(rs["#{cl[:select_prefix]}#{i}"])
              end
            end
          end
        end
        data << d
      end
      
      if show_nodata_record?
        ulist.each do |u_id|
          d = []
          u = get_user_info(u_id)
          g = atlinf2[u_id.to_s] || {}
          u = u.merge(g)
          ucols.each do |cl|
            d << u[cl[:name]]
          end
          gcols.each do |cl|
            d << u[cl[:name]]
          end
          tcols.each do |cl|
            if cl[:unit] == :duration
              d << duration_fmt(0)
            else
              d << number_fmt(0)
            end
          end
          if defined? @dsel_range and (not @dsel_range.nil?) 
            @dsel_range.each_with_index do |dt,i|
              scols.each do |cl|
                if cl[:unit] == :duration
                  d << duration_fmt(0)
                else
                  d << number_fmt(0)
                end
              end
            end
          end
          data << d
        end
      end
      
      sdata = []
      tcols.each do |cl|
        if cl[:unit] == :duration
          sdata << duration_fmt(summary_data["s#{cl[:select_prefix]}"])
        else
          sdata << summary_data["s#{cl[:select_prefix]}"].to_i
        end
      end
      @dsel_range.each_with_index do |dt,i|
        summary_data["ad#{i}"] = summary_data["td#{i}"].to_i / summary_data["nc#{i}"].to_i rescue 0
        scols.each do |cl|
          if cl[:unit] == :duration
            sdata << duration_fmt(summary_data["#{cl[:select_prefix]}#{i}"])
          else
            sdata << number_fmt(summary_data["#{cl[:select_prefix]}#{i}"])
          end
        end
      end

      @footer[:data] = Array.new(ucols.length + gcols.length)
      @footer[:data] = @footer[:data].concat(sdata)
      @footer[:data][0] = "Total"
      
      return data
    end
    
    def sql_data
      sql = []
      sql << "SELECT v.agent_id, DATE(start_time) AS call_date, COUNT(0) AS call_count, MAX(duration) AS max_duration, SUM(duration) AS total_duration"
      sql << "FROM voice_logs v"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY v.agent_id, call_date"
      sql_s1 = jn_sql(sql)
      
      sql = []
      select = [
        "s1.agent_id",
        "SUM(s1.call_count) AS snc",
        "SUM(s1.total_duration) AS std",
        "MAX(s1.max_duration) AS smd",
        "COUNT(s1.call_date) AS day_count"
      ] 
      
      if has_date_range?
        @dsel_range.each_with_index do |d,i|
          case @opts[:period_by]
          when 'daily'
            select << "SUM(IF(dc.id=#{d[:s_key]},call_count,0)) AS nc#{i}"
            select << "SUM(IF(dc.id=#{d[:s_key]},total_duration,0)) AS td#{i}"
            select << "MAX(IF(dc.id=#{d[:s_key]},max_duration,0)) AS md#{i}"
          when 'weekly'
            yk = d[:s_key].to_s[0,4]
            wk = d[:s_key].to_s[4,2]
            select << "SUM(IF(dc.stats_year=#{yk} AND dc.stats_week=#{wk},call_count,0)) AS nc#{i}"
            select << "SUM(IF(dc.stats_year=#{yk} AND dc.stats_week=#{wk},total_duration,0)) AS td#{i}"
            select << "SUM(IF(dc.stats_year=#{yk} AND dc.stats_week=#{wk},max_duration,0)) AS md#{i}"
          when 'monthly'
            select << "SUM(IF(dc.stats_yearmonth=#{d[:s_key]},call_count,0)) AS nc#{i}"
            select << "SUM(IF(dc.stats_yearmonth=#{d[:s_key]},total_duration,0)) AS td#{i}"
            select << "SUM(IF(dc.stats_yearmonth=#{d[:s_key]},max_duration,0)) AS md#{i}"
          end
        end
      end
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM (#{sql_s1}) s1"
      sql << "JOIN statistic_calendars dc ON s1.call_date = dc.stats_date AND dc.stats_hour = -1"
      if case_of?([:aeoncol]) and (@opts[:group_name].present? or @opts[:section_name].present?)
        sql << "JOIN (#{sql_join_find_by_atl}) s2 ON s1.agent_id = s2.agent_id"
      end
      sql << "GROUP BY agent_id"
      sql << "ORDER BY SUM(call_count) DESC"
      
      sql = jn_sql(sql)      
      return sql
    end
    
    def get_where
      conds = []
      conds << "v.flag <> 'D'"
      conds << "v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      if @opts[:agent_name].present?
        conds << sql_user_exist(@opts[:agent_name],"agent_id")
      end
      if @opts[:group_name].present?
        if case_of?([:aeoncol])
          # nothing (see join)
        else
          conds << sql_user_exist_by_group(@opts[:group_name],"v.agent_id")
        end
      end
      if @opts[:call_direction].present?
        conds << "v.call_direction = '#{@opts[:call_direction]}'"  
      end
      return conds
    end
    
    # end class    
  end
end