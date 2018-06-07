module EvaluationReport
  class CheckingDetailReport < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Checking Detail Report"
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
    end
    
    def initial_header
      row_cnt = @headers.length
      cols = []
      cols << new_element("Agent Name", 1, row_cnt)
      cols << new_element("Call Date", 1, row_cnt)
      cols << new_element("Caller No", 1, row_cnt)
      cols << new_element("Dialed No", 1, row_cnt)
      cols << new_element("Result",1, row_cnt)
      cols << new_element("Comment by Reviewer", 1, row_cnt)
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
        d << u[:display_name]
        d << "#{rs["call_date"].strftime("%Y-%m-%d")} #{rs["call_time"].strftime("%H:%M:%S")}"
        d << rs["ani"]
        d << rs["dnis"]
        d << rs["checked_result"]
        d << rs["comment"]
        data << d
      end
      
      return data
    end

    def sql_list
      sql = []
      
      select = [
        "l.user_id AS agent_id",
        "l.checked_result",
        "l.evaluated_by",
        "c.call_date",
        "c.call_time",
        "c.ani",
        "c.dnis",
        "cm.comment"
      ]
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "JOIN evaluation_plans p ON p.id = l.evaluation_plan_id"
      sql << "LEFT JOIN (SELECT evaluation_log_id, comment FROM evaluation_comments WHERE comment_type = 'C') cm ON cm.evaluation_log_id = l.id"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY l.evaluated_by"
      sql << "ORDER BY COUNT(0) DESC"
      return jn_sql(sql)
    end
    
    def get_where
      whs = []
      whs << "l.flag <> 'D'"
      whs << "p.flag <> 'D'"
      whs << "l.checked_by > 0 AND l.checked_result IS NOT NULL"
      whs << "l.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      whs << "c.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      if @opts[:qa_agent_name].present?
        whs << "EXISTS (SELECT 1 FROM users u WHERE #{sqlcond_user_name(@opts[:agent_name])} AND l.evaluated_by = u.id)"
      end
      return whs
    end
    
    # end class
  end  
end

