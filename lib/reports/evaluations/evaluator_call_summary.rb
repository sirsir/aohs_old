module EvaluationReport
  class EvaluatorCallSummary < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "QA Agent Summary Report"
      @long_durations = []
      @short_durations = []
      initial_report
      initial_header
      initial_footer
      
      log "parameters: #{@opts.inspect}"
    end
    
    def initial_header
      row_cnt = @headers.length
      cols = []
      if @opts[:row_by] == "agent"
        cols << new_element("Employee ID", 1, row_cnt)
        cols << new_element("Agent", 1, row_cnt)
        cols << new_element("Group", 1, row_cnt)
        cols << new_element("Evaluated By", 1, row_cnt)
      else
        cols << new_element("Employee ID", 1, row_cnt)
        cols << new_element("QA Agent", 1, row_cnt)
        cols << new_element("Group", 1, row_cnt)
      end
      cols << new_element("Total Records", 1, row_cnt)
      duration_range_for_qms.each_with_index do |rx,i|
        cols << new_element(rx.display_name, 1, row_cnt) 
      end
      if Settings.statistics.long_duration > 0
        cols << new_element("% Long Call", 1, row_cnt)
      end
      if @opts[:row_by] == "agent"
        cols << new_element("Private Call", 1, row_cnt)
      end
      add_header(cols,0,0)
    end
    
    def initial_footer
      @footer = {}
    end
    
    def get_result
      data = get_data
      ret = {
        headers: @headers,
        data: data,
        footer: @footer
      }
      return ret
    end
    
    def to_xlsx
      wb = Axlsx::Package.new
      ws = wb.workbook.add_worksheet(name: 'report')
      style = set_sheet_style(ws)      
      
      get_xlsx_titles.each_with_index do |row,i|
        ws.add_row row, style: style[:title]
      end
      
      get_xlsx_filters.each_with_index do |row,i|
        ws.add_row row, style: style[:filter]
      end
      
      headers, spans = get_xlsx_headers
      headers.each_with_index do |row,i|
        ws.add_row row, style: style[:thead]
      end
      spans.each do |cell|
        ws.merge_cells cell
      end
      
      data = get_data
      data.each do |row|
        ws.add_row row, style: style[:all]
      end
      
      ws.add_row @footer[:data], style: style[:tfoot]
      
      get_average_col_widths(headers.last.length).each_with_index do |w,i|
        ws.column_info[i].width = w
      end

      @out_fpath = xlsx_fname(@opts[:report_name])
      wb.serialize(@out_fpath)

      return {
        path: @out_fpath
      }
    end
    
    def get_data
      data = []
      summary_data = []
      
      result = select_sql(sql_list)
      pvt_result = select_sql(sql_private_count)
      
      result.each do |rs|
        d = []
        s_idx = 0 # summary index
        
        u = get_user_info(rs["agent_id"])
        d << u[:employee_id]
        d << u[:display_name]
        d << u[:group_name]
        if @opts[:row_by] == "agent"
          ev = rs["evaluator_id"].to_s.split(",")
          nm = ev.map { |eu| get_user_info(eu)[:display_name] }
          d << nm.join(", ")
        end
        
        #d << rs["total_records"].to_i
        d_total = 0
        duration_range_for_qms.each_with_index do |rx,i|
          d_total += rs["col#{i}"].to_i
        end
        
        d << d_total
        summary_data[s_idx] = summary_data[s_idx].to_i + d_total
        s_idx += 1
        
        duration_range_for_qms.each_with_index do |rx,i|
          d_val = rs["col#{i}"].to_i
          d << d_val
          summary_data[s_idx] = summary_data[s_idx].to_i + d_val
          s_idx += 1
        end
        
        if Settings.statistics.long_duration > 0
          d_val = (rs["long_duration_count"].to_f/rs["total_records"].to_f*100.0).round(2)
          d << StringFormat.pct_format(d_val)
          summary_data[s_idx] = summary_data[s_idx].to_f + d_val
          s_idx += 1
        end
        
        if @opts[:row_by] == "agent"
          pvt = pvt_result.select { |p| p["agent_id"].to_i == rs["agent_id"].to_i }
          d_val = (pvt.empty? ? 0 : pvt.first["pvt_count"].to_i) 
          d << d_val
          summary_data[s_idx] = summary_data[s_idx].to_i + d_val
          s_idx += 1
        end
        
        data << d
      end
      
      if @opts[:row_by] == "agent"
        @footer[:data] = ["Grand Total",nil,nil,nil].concat(summary_data)
      else
        @footer[:data] = ["Grand Total",nil,nil].concat(summary_data)
      end
      
      return data
    end

    def sql_list
      sql = []
      
      if @opts[:row_by] == "agent"
        select = [
          "l.user_id AS agent_id",
          "COUNT(DISTINCT l.user_id) AS total_agents",
          "COUNT(0) AS total_records",
          "l.evaluated_by AS evaluator_id"
        ]
      else
        select = [
          "l.evaluated_by AS agent_id",
          "COUNT(DISTINCT l.user_id) AS total_agents",
          "COUNT(0) AS total_records"
        ]
      end
      duration_range_for_qms.each_with_index do |rx,i|
        if rx.upper_bound.nil?
          select << "SUM(IF(c.duration >= #{rx.lower_bound},1,0)) AS col#{i}"
        else
          select << "SUM(IF(c.duration BETWEEN #{rx.lower_bound} AND #{rx.upper_bound},1,0)) AS col#{i}"
        end
      end
      #if Settings.statistics.short_duration > 0
      #  select << "SUM(IF(c.duration <= #{Settings.statistics.short_duration},1,0)) AS short_duration_count"
      #end
      if Settings.statistics.long_duration > 0
        select << "SUM(IF(c.duration >= #{Settings.statistics.long_duration},1,0)) AS long_duration_count"
      end
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "JOIN evaluation_plans p ON p.id = l.evaluation_plan_id"
      if defined? @dsel_range and not @dsel_range.nil?
        sql << "JOIN statistic_calendars c ON c.stats_date = d.call_date AND ca.stats_hour = -1"
      end
      sql << "WHERE #{jn_where(get_where)}"
      if @opts[:row_by] == "agent"
        sql << "GROUP BY l.user_id, l.evaluated_by"
      else
        sql << "GROUP BY l.evaluated_by"
      end
      sql << "ORDER BY COUNT(0) DESC"
      return jn_sql(sql)
    end
    
    def sql_private_count
      pvt = CallCategory.only_private.first
      unless pvt.nil?
        pvt = pvt.id
      else
        pvt = 0
      end
      sql = []
      sql << "SELECT v.agent_id, COUNT(0) AS pvt_count"
      sql << "FROM voice_logs v"
      sql << "JOIN call_classifications cl ON cl.voice_log_id = v.id AND cl.call_category_id = #{pvt}"
      sql << "WHERE v.start_time BETWEEN '#{@opts[:sdate]} 00:00:00' AND '#{@opts[:edate]} 23:59:59'"
      return jn_sql(sql)
    end
    
    def get_where
      whs = []
      whs << "l.flag <> 'D'"
      whs << "p.flag <> 'D'"
      whs << "l.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      whs << "c.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      if @opts[:agent_name].present?
        whs << "EXISTS (SELECT 1 FROM users u WHERE #{sqlcond_user_name(@opts[:agent_name])} AND l.evaluated_by = u.id)"
      end
      if @opts[:user_id].present?
        whs << "l.evaluated_by = #{@opts[:user_id]}"
      end
      
      return whs
    end
    
    def duration_range_for_qms
      l = duration_range.length
      return duration_range[1,l-1]
    end
    
    # end class
  end  
end

