module EvaluationReport
  class AsstDetailLog < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Auto Assessment Report"
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
    end
    
    def initial_header
      @col_quests = []
      row_cnt = @headers.length
      cols = []
      
      cols << new_element("Call ID", 1, row_cnt)
      cols << new_element("File ID", 1, row_cnt)
      @questions = qa_questions
      @questions.each do |q|
        cols << new_element(q[:title], 1, row_cnt)
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
      
      result = select_sql(sql_details)
      answers = select_sql(sql_answers)
      result.each do |rs|
        d = []
        d << rs["id"]
        d << rs["voice_file_url"].split("/").last
        l_ans = answers.select { |a| a["voice_log_id"].to_i == rs["id"].to_i } 
        @questions.each do |q|
          f = l_ans.index { |a| a["evaluation_question_id"].to_i == q[:id] }
          if not f.nil? and f >= 0
            d << l_ans[f]["result"].to_s.capitalize
          else
            d << "No"
          end
        end
        data << d
      end
      
      return data
    end
    
    def qa_questions
      quests = []
      result = select_sql(sql_list_questions)
      result.each do |q|
        qx = EvaluationQuestion.where(id: q["evaluation_question_id"]).first
        quests << {
          id: qx.id,
          title: qx.title
        }
      end
      return quests
    end
    
    def sql_list_questions
      sql = []
      sql << "SELECT l.evaluation_plan_id, l.evaluation_question_id"  
      sql << "FROM voice_logs v JOIN auto_assessment_logs l ON v.id = l.voice_log_id"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY l.evaluation_plan_id, l.evaluation_question_id"
      return jn_sql(sql)
    end
    
    def sql_details
      sql = []      
      sql << "SELECT v.id, v.voice_file_url FROM voice_logs v"
      sql << "WHERE EXISTS (SELECT 1 FROM auto_assessment_logs l WHERE v.id = l.voice_log_id)"
      sql << "AND #{jn_where(get_where)}"
      return jn_sql(sql)
    end

    def sql_answers
      sql = [] 
      sql << "SELECT l.voice_log_id, l.evaluation_question_id, l.result"
      sql << "FROM voice_logs v JOIN auto_assessment_logs l ON v.id = l.voice_log_id"
      sql << "WHERE #{jn_where(get_where)}"
      return jn_sql(sql)
    end
    
    def get_where
      whs = []
      if @opts[:call_type] == "Sale (TM)"
        cc = CallCategory.where(code_name: "TM").first
        whs << "EXISTS (SELECT 1 FROM call_classifications c WHERE c.voice_log_id = v.id AND c.call_category_id = '#{cc.id}')"
      else
        cc = CallCategory.where(code_name: "CS").first
        whs << "EXISTS (SELECT 1 FROM call_classifications c WHERE c.voice_log_id = v.id AND c.call_category_id = '#{cc.id}')"
      end
      whs << "v.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      whs << "v.duration > 0"
      return whs
    end

    # end class
  end
end