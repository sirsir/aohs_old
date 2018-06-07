module EvaluationReport
  class AcsNgUsageCallSummary < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "NG Usage Summary Report"

      # get ng usage
      ng_codes = ["NGWORD_USAGE"]
      @ng_questions = EvaluationQuestion.find_by_code(ng_codes).all
      @ng_codes = @ng_questions.map { |q| q.id }
      @ng_choices = choice_list(@ng_questions)
      
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
      log "ng usage codes: #{@ng_codes.to_json}"
    end
    
    def initial_header
      row_cnt = @headers.length
      
      # row 1  
      cols = []
      group_leaders_list.each do |leader|
        cols << new_element(leader.display_name, 1, 2)
      end
      cols << new_element("Group", 1, 2)
      cols << new_element("Total Staff", 1, 2)
      cols << new_element("Total Monitor", 1, 2)
      cols << new_element("AVG.Monitor/Staff", 1, 2)
      cols << new_element("NG Word Usage", @ng_choices.length, 1)
      cols << new_element("Total", 1, 2)
      add_header(cols,0,0)
      
      ## row 2
      cols = []
      @ng_choices.each do |cho|
        cols << new_element(cho, 1, 1) 
      end
      add_header(cols, 1, 0)
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
      data = {}
      result = select_sql(sql_list)
      result2 = select_sql(sql_list_duration)
      
      # map data
      result.each do |rs|
        group_id = rs["group_id"].to_i
        cho = rs["choice_title"]
        qu = "ng_usage"
        data[group_id] = {} if data[group_id].nil?
        data[group_id][qu] = {} if data[group_id][qu].nil?
        data[group_id][qu][cho] = data[group_id][qu][cho].to_i + rs["total_records"].to_i
      end
      
      date_out = []
      data.each do |group_id, rs|
        d = []
        g = get_group_info(group_id)
        group_leaders_list.each do |leader|
          d << g[leader.display_name]
        end
        d << g[:display_name]
        dx = (result2.select { |x| x["group_id"].to_i == group_id.to_i }).first
        d << dx["agent_count"]
        d << dx["total_records"]
        d << dx["total_records"].to_i/dx["agent_count"].to_i
        tt_ng = 0
        @ng_choices.each do |cho|
          v = rs["ng_usage"][cho].to_i rescue 0
          d << v
          tt_ng += v.to_i
        end
        d << tt_ng
        date_out << d
      end
      
      return date_out
    end
    
    def sql_list
      sql = []
      
      select = [
        "s.group_id",
        "s.choice_title",
        "SUM(s.record_count) AS total_records"
      ]
      
      group = [
        "s.group_id",
        "s.choice_title",
      ]
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_question_stats s"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY #{jn_groups(group)}"      

      return jn_sql(sql)
    end
    
    def choice_list(questions)
      choices = []
      questions.each do |qu|
        chos = qu.evaluation_answers.not_deleted.first.sorted_answer_list
        chos.each do |cho|
          unless choices.include?(cho["title"])
            choices << cho["title"]
          end
        end
      end
      return choices
    end

    def sql_list_duration
      sql = []
      
      select = [
        "l.group_id AS group_id",
        "COUNT(DISTINCT l.user_id) AS agent_count",
        "COUNT(0) AS total_records",
      ]
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "JOIN evaluation_plans p ON p.id = l.evaluation_plan_id"
      sql << "WHERE #{jn_where(get_where2)}"
      sql << "GROUP BY l.group_id"
      sql << "ORDER BY COUNT(0) DESC"
      return jn_sql(sql)
    end
    
    def get_where
      whs = []
      whs << "s.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      whs << "s.evaluation_question_id IN (#{@ng_codes.join(",")},0)"
      whs << "s.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      if @opts[:group_name].present?
        whs << "EXISTS (SELECT 1 FROM groups g WHERE #{sqlcond_group_name(@opts[:group_name])} AND s.group_id = g.id)"
      end
      return whs
    end
    
    def get_where2
      whs = []
      whs << "l.flag <> 'D'"
      whs << "p.flag <> 'D'"
      whs << "c.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      whs << "l.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      if @opts[:group_name].present?
        whs << "EXISTS (SELECT 1 FROM groups g WHERE #{sqlcond_group_name(@opts[:group_name])} AND l.group_id = g.id)"
      end
      return whs
    end

    # end class
  end  
end

