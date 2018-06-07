module EvaluationReport
  class CheckingSummaryReport < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Checking Summary Report"
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
    end
    
    def initial_header
      row_cnt = @headers.length
      cols = []
      if @opts[:row_by] == "agent"
        cols << new_element("Checked By", 1, row_cnt)
        cols << new_element("Evaluated By", 1, row_cnt)
        cols << new_element("Employee ID", 1, row_cnt)
        cols << new_element("Agent", 1, row_cnt)
      else
        cols << new_element("QA Agent", 1, row_cnt)
        cols << new_element("Total Agent", 1, row_cnt)
      end
      cols << new_element("Total Checked", 1, row_cnt)
      cols << new_element("Correct", 1, row_cnt)
      cols << new_element("Wrong", 1, row_cnt)
      
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
        if @opts[:row_by] == "agent"
          uc = get_user_info(rs["checker_id"])
          d << uc[:display_name]
          uq = get_user_info(rs["qa_agent_id"])
          d << uq[:display_name]
          ua = get_user_info(rs["agent_id"])
          d << ua[:employee_id]
          d << ua[:display_name]
        else
          u = get_user_info(rs["agent_id"])
          d << u[:display_name]
          d << rs["total_agents"].to_i
        end
        d << rs["total_correct"].to_i + rs["total_wrong"].to_i
        d << rs["total_correct"].to_i
        d << rs["total_wrong"].to_i
        data << d
      end
      
      return data
    end
        
    def sql_list
      sql = []
      
      if @opts[:row_by] == "agent"
        select = [
          "l.user_id AS agent_id",
          "l.evaluated_by AS qa_agent_id",
          "l.checked_by AS checker_id",
          "COUNT(0) AS total_records",
          "SUM(IF(l.checked_result='C',1,0)) AS total_correct",
          "SUM(IF(l.checked_result='W',1,0)) AS total_wrong"
        ]
      else
        select = [
          "l.evaluated_by AS agent_id",
          "COUNT(DISTINCT l.user_id) AS total_agents",
          "COUNT(0) AS total_records",
          "SUM(IF(l.checked_result='C',1,0)) AS total_correct",
          "SUM(IF(l.checked_result='W',1,0)) AS total_wrong"
        ]
      end
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "JOIN evaluation_plans p ON p.id = l.evaluation_plan_id"
      sql << "WHERE #{jn_where(get_where)}"
      if @opts[:row_by] == "agent"
        sql << "GROUP BY l.user_id, l.evaluated_by" 
      else
        sql << "GROUP BY l.evaluated_by"
      end
      sql << "ORDER BY COUNT(0) DESC"
      return jn_sql(sql)
    end
    
    def get_where
      whs = []
      whs << "l.flag <> 'D'"
      whs << "p.flag <> 'D'"
      whs << "l.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      whs << "c.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      whs << "l.checked_by IS NOT NULL"
      if @opts[:agent_name].present?
        whs << "EXISTS (SELECT 1 FROM users u WHERE #{sqlcond_user_name(@opts[:agent_name])} AND l.evaluated_by = u.id)"
      end
      return whs
    end
    
    # end class
  end  
end

