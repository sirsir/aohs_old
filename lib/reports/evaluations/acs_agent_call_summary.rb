module EvaluationReport
  class AcsAgentCallSummary < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Agent Evaluation Summary Report (Greeting and NG Usage)"

      # get greeting question
      greeting_codes = ["GRET1","GREETING01"]
      @greeting_questions = EvaluationQuestion.find_by_code(greeting_codes).all
      @greeting_codes = @greeting_questions.map { |q| q.id }
      @greeting_choices = choice_list(@greeting_questions)
      
      # get ng usage
      ng_codes = ["NGWORD_USAGE"]
      @ng_questions = EvaluationQuestion.find_by_code(ng_codes).all
      @ng_codes = @ng_questions.map { |q| q.id }
      @ng_choices = choice_list(@ng_questions)
      
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
      log "greeting codes: #{@greeting_codes.to_json}"
      log "ng codes: #{@ng_codes.to_json}"
    end
    
    def initial_header
      row_cnt = @headers.length
      
      # row 1  
      cols = []
      cols << new_element("Employee ID", 1, 2)
      cols << new_element("Agent Name", 1, 2)
      get_group_columns.each do |c|
        cols << new_element(c[:display_name], 1, 2)
      end
      group_leaders_list.each do |leader|
        cols << new_element(leader.display_name, 1, 2)
      end
      cols << new_element("Total Records", 1, 2)
      cols << new_element("Duration", duration_range_qms.length, 1)
      cols << new_element("Greeting", @greeting_choices.length, 1)
      cols << new_element("NG Word Usage", @ng_choices.length, 1)
      add_header(cols,0,0)
      
      ## row 2
      cols = []
      duration_range_qms.each_with_index do |rx,i|
        cols << new_element(rx.display_name, 1, 1) 
      end
      @greeting_choices.each do |cho|
        cols << new_element(cho, 1, 1) 
      end
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
        agent_id = rs["agent_id"].to_i
        cho = rs["choice_title"]
        qu = nil
        if @greeting_codes.include?(rs["evaluation_question_id"])
          qu = "greeting"
        else
          qu = "ng_usage"
        end
        data[agent_id] = {} if data[agent_id].nil?
        data[agent_id][qu] = {} if data[agent_id][qu].nil?
        data[agent_id][qu][cho] = data[agent_id][qu][cho].to_i + rs["total_records"].to_i
      end
      
      date_out = []
      data.each do |agent_id, rs|
        d = []
        u = get_user_info(agent_id)
        d << u[:employee_id]
        d << u[:display_name]
        get_group_columns.each do |c|
          d << u[c[:field_name]]
        end
        group_leaders_list.each do |leader|
          d << u[leader.display_name]
        end
        dx = (result2.select { |x| x["agent_id"].to_i == agent_id.to_i }).first
        d << (dx.nil? ? 0 : dx["total_records"].to_i)
        duration_range_qms.each_with_index do |rx,i|
          d << (dx.nil? ? 0 : dx["col#{i}"])
        end
        @greeting_choices.each do |cho|
          v = rs["greeting"][cho].to_i rescue 0
          d << v
        end
        @ng_choices.each do |cho|
          v = rs["ng_usage"][cho].to_i rescue 0
          d << v
        end
        date_out << d
      end
      
      return date_out
    end
    
    def sql_list
      sql = []
      
      select = [
        "s.agent_id",
        "s.evaluation_question_id",
        "s.choice_title",
        "SUM(s.record_count) AS total_records"
      ]
      
      group = [
        "s.agent_id",
        "s.evaluation_question_id",
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
        "l.user_id AS agent_id",
        "COUNT(0) AS total_records",
      ]
      duration_range_qms.each_with_index do |rx,i|
        if rx.upper_bound.nil?
          select << "SUM(IF(c.duration >= #{rx.lower_bound},1,0)) AS col#{i}"
        else
          select << "SUM(IF(c.duration BETWEEN #{rx.lower_bound} AND #{rx.upper_bound},1,0)) AS col#{i}"
        end
      end
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "JOIN evaluation_plans p ON p.id = l.evaluation_plan_id"
      sql << "WHERE #{jn_where(get_where2)}"
      sql << "GROUP BY l.user_id"
      sql << "ORDER BY COUNT(0) DESC"
      return jn_sql(sql)
    end
    
    def get_where
      codes = @ng_codes
      codes = codes.concat(@greeting_codes)
      whs = []
      whs << "s.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      whs << "s.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      whs << "s.evaluation_question_id IN (#{codes.join(",")},0)"
      if @opts[:agent_name].present?
        whs << "EXISTS (SELECT 1 FROM users u WHERE #{sqlcond_user_name(@opts[:agent_name])} AND s.agent_id = u.id)"
      end
      if @opts[:group_name].present?
        whs << "EXISTS (SELECT 1 FROM groups g WHERE #{sqlcond_group_name(@opts[:group_name])} AND s.group_id = g.id)"
      end
      return whs
    end
    
    def get_where2
      whs = []
      whs << "l.flag <> 'D'"
      whs << "p.flag <> 'D'"
      whs << "l.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      whs << "c.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      if @opts[:agent_name].present?
        whs << "EXISTS (SELECT 1 FROM users u WHERE #{sqlcond_user_name(@opts[:agent_name])} AND l.user_id = u.id)"
      end
      if @opts[:group_name].present?
        whs << "EXISTS (SELECT 1 FROM groups g WHERE #{sqlcond_group_name(@opts[:group_name])}  AND l.group_id = g.id)"
      end
      return whs
    end
    
    def duration_range_qms
      # fix for qms
      l = duration_range.length
      return duration_range[1,l-1]
    end
    
    # end class
  end  
end

