module EvaluationReport
  class AcsEvaluationCnt < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Agent Evaluation Summary Report"
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
    end
    
    def initial_header
      @ng_question = EvaluationQuestion.where(code_name: ["NGWORD_USAGE"]).first
      @col_quests = []
      row_cnt = @headers.length
      cols = []
      
      cols << new_element("Employee ID", 1, 2)
      cols << new_element("Agent's Name", 1, 2)
      cols << new_element("Group", 1, 2)
      group_leaders_list.each do |leader|
        cols << new_element(leader.display_name, 1, 2)
      end
      cols << new_element("Total Records", 1, 2)
      cols << new_element("AVG Score", 1, 2)

      # score details
      tmp_quest = get_list_questions
      tmp_quest.each do |c|
        @col_quests << c["matched_id"].to_i
      end
      tmp_ans = get_list_answers
      
      tmp_quest.each do |c|
        span_cnt = (tmp_ans.select { |h| h[:question_id] == c["matched_id"] }).length
        cols << new_element(c["col_title"], span_cnt, 1)
      end
      add_header(cols,0,-1)
      
      # row 2
      # answers
      cols = []
      tmp_ans.each do |c|
        cols << new_element(c[:answer_title], 1, 1)
      end
      add_header(cols,1,0)
      
    end

    def get_result
      @opts[:limit] = 10000
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
      
      tmp_ans = get_list_answers
      result = select_sql(sql_list_evaluation)
      result_scores = select_sql(sql_details)
      result_ans = sql_answer_list

      result.each do |rs|
        d = []
        u = get_user_info(rs["agent_id"], rs["group_id"])
        d << u[:employee_id]
        d << u[:display_name]
        d << u[:group_name]
        group_leaders_list.each do |leader|
          d << u[leader.display_name]
        end
        d << rs["total_records"].to_i        

        ob = (result_scores.select { |x|
          rs["agent_id"].to_i == x["agent_id"].to_i
        }).first
        if ob.blank?
          d << nil
        else
          d << ob["sum_score"]/rs["total_records"].to_i
        end
        tmp_ans.each do |ans|
          key = "#{ans[:question_id]}_#{ans[:answer_title]}"
          if result_ans[rs["agent_id"].to_s].nil? or result_ans[rs["agent_id"].to_s][key].nil?
            d << 0
          else
            d << result_ans[rs["agent_id"].to_s][key].to_i
          end
        end
        data << d
      end
      
      return data
    end

    def sql_list_evaluation
      select = [
        "l.user_id AS agent_id","MAX(l.group_id) AS group_id",
        "COUNT(DISTINCT l.id) AS total_records",
        "GROUP_CONCAT(p.evaluation_grade_setting_id) AS grade_list"
      ]
      sql = []
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_plans p ON l.evaluation_plan_id = p.id"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY l.user_id"
      if @opts[:limmit].present?
        sql << "LIMIT #{@opts[:limit]}"
      end
      return jn_sql(sql)
    end
    
    def get_list_questions
      sql = []
      sql << "SELECT DISTINCT s.evaluation_question_id"
      sql << "FROM evaluation_score_logs s"
      sql << "WHERE EXISTS (SELECT 1"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
      sql << "JOIN evaluation_plans p ON l.evaluation_plan_id = p.id"
      sql << "WHERE #{jn_where(get_where)} AND s.evaluation_log_id = l.id)"
      result = select_sql(jn_sql(sql))
      result = result.map{ |c| c["evaluation_question_id"] }
      return get_column_criteria(@opts[:column_by], result)
    end
    
    def get_list_answers
      out_ans = []
      answers = EvaluationAnswer.not_deleted.where(evaluation_question_id: @col_quests).all
      @col_quests.each do |q_id|
        if q_id == @ng_question.id
          out_ans << {
            question_id: q_id,
            answer_title: "0"
          }
          out_ans << {
            question_id: q_id,
            answer_title: ">=1"
          }
        else
          answers.each do |anss|
            if q_id == anss.evaluation_question_id
              anss.answer_list.each do |ans|
                out_ans << {
                  question_id: q_id,
                  answer_title: ans["title"]
                }
              end
            end
          end
        end
      end
      return out_ans
    end
    
    def sql_detail_by_question
      sql = []
      sql << "SELECT l.id, l.user_id"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_plans p ON l.evaluation_plan_id = p.id"
      sql << "JOIN evaluation_calls c ON c.evaluation_log_id = l.id"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY l.id, l.user_id"
      
      sql1 = jn_sql(sql)
      sql = []
      sql << "SELECT l.user_id AS agent_id,"
      sql << "SUM(s.weighted_score) AS ws_score, SUM(s.max_score) AS max_score, SUM(s.actual_score) AS sum_score, COUNT(0) AS total_records,"
      sql << "GROUP_CONCAT(s.comment) AS comments"
      sql << "FROM (#{sql1}) l"
      sql << "JOIN evaluation_score_logs s ON l.id = s.evaluation_log_id"
      sql << "LEFT JOIN evaluation_question_display d ON s.evaluation_question_id = d.question_id"
      sql << "GROUP BY l.user_id"
      return jn_sql(sql)
    end 
    
    def sql_answer_list
      sql = []
      sql << "SELECT l.id, l.user_id"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_plans p ON l.evaluation_plan_id = p.id"
      sql << "JOIN evaluation_calls c ON c.evaluation_log_id = l.id"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY l.id, l.user_id"
      
      sql1 = jn_sql(sql)
      sql = []
      sql << "SELECT l.user_id, l.id AS evaluation_log_id, s.evaluation_question_id, s.answer"
      sql << "FROM evaluation_score_logs s"
      sql << "JOIN (#{sql1}) l ON l.id = s.evaluation_log_id"
      
      sql = jn_sql(sql)
      tmp = select_sql(sql)
      
      tmp_out = {}
      tmp.each do |l|
        agent_id = l["user_id"].to_s
        tmp_out[agent_id] = {} if tmp_out[agent_id].nil?
        ans = JSON.parse(l["answer"])
        ans.each do |an|
          next if an["deduction"] == "uncheck"
          if l["evaluation_question_id"].to_i == @ng_question.id
            key = "#{l["evaluation_question_id"]}_>=1"
            key2 = "#{l["evaluation_question_id"]}_0"
            if an["deduction"] == "checked"
              tmp_out[agent_id][key] = 1
              tmp_out[agent_id][key2] = 0
            else
              tmp_out[agent_id][key] = 0
              tmp_out[agent_id][key2] = 1
            end
          else
            key = "#{l["evaluation_question_id"]}_#{an["title"]}"
            tmp_out[agent_id][key] = tmp_out[agent_id][key].to_i + 1
          end
        end
      end
      return tmp_out
    end
    
    def sql_details
      sql = sql_detail_by_question
      return sql
    end
    
    def get_where
      whs = []
      whs << "p.flag <> 'D'"
      whs << "l.flag <> 'D'"
      whs << "l.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      whs << "c.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      if @opts[:agent_name].present?
        whs << "EXISTS (SELECT 1 FROM users u WHERE #{sqlcond_user_name(@opts[:agent_name])} AND l.user_id = u.id)"
      end
      if @opts[:group_name].present?
        whs << "EXISTS (SELECT 1 FROM groups g WHERE #{sqlcond_group_name(@opts[:group_name])} AND l.group_id = g.id)"
      end
      return whs
    end

    # end class
  end
end