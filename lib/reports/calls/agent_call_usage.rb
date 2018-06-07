module CallStatisticsReport
  class AgentCallUsage < CallReportBase
    
    def initialize(opts={})
      set_params opts
      set_option :report_name, "Agent Call Usage Report"
      initial_report
      initial_header
    end
    
    def initial_header
      ucols = agent_info_columns
      gcols = group_info_columns
      xcols = [].concat(ucols).concat(gcols)
      
      # row 1
      cols = []
      cols = []
      xcols.each do |cl|
        cols << new_element(cl[:display_name], 1, 2)
      end
      cols << new_element("Total Call", 1, 2)
      cols << new_element("Calls/Day", 1, 2)
      cols << new_element("Total Duration", 1, 2)
      cols << new_element("Inbound", 4, 1)
      cols << new_element("Outbound", 4, 1)
      add_header(cols, 0, 0)
      
      # row 2
      cols = []
      cols << new_element("Total Calls", 1, 1)
      cols << new_element("Duration", 1, 1)
      cols << new_element("Avg Duration", 1, 1)
      cols << new_element("Max Duration", 1, 1)
      cols << new_element("Total", 1, 1)
      cols << new_element("Duration", 1, 1)
      cols << new_element("Avg Duration", 1, 1)
      cols << new_element("Max Duration", 1, 1) 
      add_header(cols, 1, 0)
    end
    
    def get_result
      return {
        headers: @headers,
        data: get_data
      }
    end
    
    def to_xlsx
      return to_xlsx_file_default
    end
  
    private

    def get_data
      data = []
      result = select_sql(sql_data)
      
      # map result
      ds = {}
      result.each do |rs|
        agent_id = rs["agent_id"].to_s
        ds[agent_id] = {} if ds[agent_id].nil?
        case rs["call_direction"]
        when "i"
          ds[agent_id]["i_total"] = rs["total_record"].to_i
          ds[agent_id]["i_duration"] = rs["total_duration"].to_i
          ds[agent_id]["i_avg_duration"] = rs["total_duration"].to_i/rs["total_record"].to_i
          ds[agent_id]["i_max_duration"] = rs["max_duration"]
          ds[agent_id]["total"] = ds[agent_id]["total"].to_i + rs["total_record"].to_i
          ds[agent_id]["total_duration"] = ds[agent_id]["total_duration"].to_i + rs["total_duration"].to_i
          ds[agent_id]["avg"] = ds[agent_id]["avg"].to_i + rs["total_record"].to_i/rs["ndays"].to_i
        when "o"
          ds[agent_id]["o_total"] = rs["total_record"].to_i
          ds[agent_id]["o_duration"] = rs["total_duration"].to_i
          ds[agent_id]["o_avg_duration"] = rs["total_duration"].to_i/rs["total_record"].to_i
          ds[agent_id]["o_max_duration"] = rs["max_duration"]
          ds[agent_id]["total"] = ds[agent_id]["total"].to_i + rs["total_record"].to_i
          ds[agent_id]["total_duration"] = ds[agent_id]["total_duration"].to_i + rs["total_duration"].to_i
          ds[agent_id]["avg"] = ds[agent_id]["avg"].to_i + rs["total_record"].to_i/rs["ndays"].to_i
        end
      end
      
      ucols = agent_info_columns
      gcols = group_info_columns
      altinf = get_list_groupinfo_from_atl
      
      ds.each do |agent_id, rs|
        d = []
        u = get_user_info(agent_id)
        g = altinf[agent_id.to_s] || {}
        u = u.merge(g)
        ucols.each do |cl|
          d << u[cl[:name]]
        end
        gcols.each do |cl|
          d << u[cl[:name]]
        end
        d << rs["total"]
        d << rs["avg"]
        d << duration_fmt(rs["total_duration"])
        ["i","o"].each do |cd|
          d << rs["#{cd}_total"].to_i
          d << duration_fmt(rs["#{cd}_duration"])
          d << duration_fmt(rs["#{cd}_avg_duration"])
          d << duration_fmt(rs["#{cd}_max_duration"])
        end
        data << d
      end
      return data
    end
    
    def sql_data
      sql = []
      select = [
        "v.agent_id",
        "v.call_direction",
        "COUNT(0) AS total_record",
        "COUNT(DISTINCT v.call_date) AS ndays",
        "SUM(v.duration) AS total_duration",
        "MAX(v.duration) AS max_duration"
      ]
      group = [
        "v.agent_id",
        "v.call_direction"
      ]
      where = []
      where << "v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      if @opts[:agent_name].present?
        where << sql_user_exist(@opts[:agent_name],"v.agent_id")
      end
      if @opts[:group_name].present?
        if case_of?([:aeoncol,:acss])
          # nothing
        else
          where << sql_user_exist_by_group(@opts[:group_name],"v.agent_id")
        end
      end      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM voice_logs v"
      if case_of?([:aeoncol]) and (@opts[:group_name].present? or @opts[:section_name].present?)
        sql << "JOIN (#{sql_join_find_by_atl}) s2 ON v.agent_id = s2.agent_id"
      end
      sql << "WHERE #{jn_where(where)}"
      sql << "GROUP BY #{jn_group(group)}"
      return jn_sql(sql)
    end
    
    # end class
  end
end