module EvaluationReport
  class EvaluatorSummary < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "QA Agent Summary Report"
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
    end
    
    def initial_header
      row_cnt = @headers.length
      
      # row 1
      cols = []
      cols << new_element("Employee ID", 1, row_cnt)
      cols << new_element("QA Agent", 1, row_cnt)
      cols << new_element("Total Records", 1, row_cnt)
      cols << new_element("Total Call Duration", 1, row_cnt)
      if defined? @dsel_range and not @dsel_range.nil?
        dmyhdr = dmy_header
        dmyhdr[:days].each do |d|
          cols << new_element(d[:full_label], 1, row_cnt) 
        end
      end
      add_header(cols,0,0)
    end
    
    def get_result
      data = get_data
      ret = {
        headers: @headers,
        data: data
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
      
      result = select_sql(sql_list)
      result.each do |rs|
        d = []
        u = get_user_info(rs["agent_id"])
        d << u[:employee_id]
        d << u[:display_name]
        d << rs["total_records"].to_i
        d << StringFormat.format_sec(rs["total_duration"])
        if defined? @dsel_range and not @dsel_range.nil?
          @dsel_range.each_with_index do |dt,i|
            d << rs["callcount_#{i}"].to_i
          end
        end
        data << d
      end
      
      return data
    end

    def sql_list
      sql = []
      
      select = [
        "l.evaluated_by AS agent_id",
        "COUNT(DISTINCT l.user_id) AS total_agents",
        "COUNT(0) AS total_records",
        "SUM(c.duration) AS total_duration"
      ]

      if defined? @dsel_range and not @dsel_range.nil?
        @dsel_range.each_with_index do |d,i|
          case @opts[:period_by]
          when 'daily'
            select << "SUM(IF(d.id=#{d[:s_key]},1,0)) AS callcount_#{i}"
          when 'weekly'
            select << "SUM(IF(d.stats_yearweek=#{d[:s_key]},1,0)) AS callcount_#{i}"
          when 'monthly'
            select << "SUM(IF(d.stats_yearmonth=#{d[:s_key]},1,0)) AS callcount_#{i}"
          end
        end
      end
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "JOIN evaluation_plans p ON p.id = l.evaluation_plan_id"
      if defined? @dsel_range and not @dsel_range.nil?
        sql << "JOIN statistic_calendars d ON d.stats_date = c.call_date AND d.stats_hour = -1"
      end
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY l.evaluated_by"
      sql << "ORDER BY COUNT(0) DESC"
      return jn_sql(sql)
    end
    
    def get_where
      whs = []
      whs << "l.flag <> 'D'"
      whs << "p.flag <> 'D'"
      whs << "l.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      whs << "c.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      if @opts[:group_name].present?
        whs << "EXISTS (SELECT 1 FROM groups g WHERE #{sqlcond_group_name(@opts[:group_name])} AND l.group_id = g.id)"
      end
      if @opts[:user_id].present?
        whs << "l.evaluated_by = #{@opts[:user_id]}"
      end
      return whs
    end
    
    # end class
  end
end