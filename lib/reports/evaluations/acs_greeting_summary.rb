module EvaluationReport
  class AcsGreetingSummary < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Greeting Summary Report"

      # get greeting question
      greeting_codes = ["GRET1","GREETING01"]
      @questions = EvaluationQuestion.find_by_code(greeting_codes).all
      @greeting_codes = @questions.map { |q| q.id }
      @choices = choice_list
      @yes_codes = @choices.take(2)
      
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
      log "greeting codes: #{@greeting_codes.to_json}"
      log "choices: #{@choices.to_json}"
    end
    
    def initial_header
      row_cnt = @headers.length
      @spancol_cnt = 1
      
      # row 1  
      cols = []
      cols << new_element("Employee ID", 1, 2)
      cols << new_element("Agent Name", 1, 2)
      get_group_columns.each do |c|
        cols << new_element(c[:display_name], 1, 2)
        @spancol_cnt += 1
      end
      group_leaders_list.each do |leader|
        cols << new_element(leader.display_name, 1, 2)
        @spancol_cnt += 1
      end
      cols << new_element("Total", @choices.length + 2, 1)
      if defined? @dsel_range and not @dsel_range.nil?
        dmyhdr = dmy_header
        dmyhdr[:days].each do |d|
          cols << new_element(d[:full_label], @choices.length, 1) 
        end
      end
      add_header(cols,0,0)
      
      # row 2
      cols = []
      @choices.each do |cho|
        cols << new_element(cho, 1, 1) 
      end
      cols << new_element("Total", 1, 1)
      cols << new_element("%", 1, 1) 
      if defined? @dsel_range and not @dsel_range.nil?
        dmyhdr = dmy_header
        dmyhdr[:days].each do |d|
          @choices.each do |cho|
            cols << new_element(cho, 1, 1) 
          end
        end
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
      data_sumt = {}
      
      # map data
      result.each do |rs|
        agent_id = rs["agent_id"].to_i
        cho = rs["choice_title"]
        d_index = @dsel_range.index { |d| d[:s_key] == rs["col_key"] }
        data[agent_id] = { total: 0 } if data[agent_id].nil?
        data[agent_id][cho] = [] if data[agent_id][cho].nil?
        data[agent_id][cho][d_index] = data[agent_id][cho][d_index].to_i + rs["total_records"].to_i
        data[agent_id]["total_" + cho] = data[agent_id]["total_" + cho].to_i + rs["total_records"].to_i
        data_sumt["total_" + cho] = data_sumt["total_" + cho].to_i + rs["total_records"].to_i
        if @yes_codes.include?(cho)
          data[agent_id]["total_yes0"] = data[agent_id]["total_yes0"].to_i + rs["total_records"].to_i
          data_sumt["total_yes0"] = data_sumt["total_yes0"].to_i + rs["total_records"].to_i
        end
        data[agent_id][:total] += rs["total_records"].to_i
        data_sumt["total"] = data_sumt["total"].to_i + rs["total_records"].to_i
      end
      
      data_out = []
      data_sum = []
      
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
        @choices.each do |cho|
          d << rs["total_" + cho].to_i
        end
        d << rs[:total].to_i
        d << ((rs[:total].to_i > 0) ? StringFormat.pct_format(data[agent_id]["total_yes0"].to_f/rs[:total].to_f*100.0) : 0)
        @dsel_range.each_with_index do |dx,i|
          data_sum[i] = [] if data_sum[i].nil?
          @choices.each_with_index do |cho,j|
            v = rs[cho][i].to_i rescue 0
            d << v
            data_sum[i][j] = data_sum[i][j].to_i + v 
          end
        end        
        data_out << d
      end

      # grand total
      if data.length > 0
        d = ["Grand Total"].concat(@spancol_cnt.times.map { |x| nil })
        @choices.each do |cho|
          d << data_sumt["total_" + cho].to_i
        end
        d << data_sumt["total"].to_i
        d << ((data_sumt["total"].to_i > 0) ? StringFormat.pct_format(data_sumt["total_yes0"].to_f/data_sumt["total"].to_f*100.0) : 0)
        @dsel_range.each_with_index do |dx,i|
          data_sum[i].each do |c|
            d << c
          end
        end
  
        data_out << d
      end
      
      return data_out
    end
    
    def duration_range
      return CallStatistic.statistic_type_ranges(:count,:all,:duration_range)
    end
    
    def sql_list
      sql = []
      
      select = [
        "s.agent_id",
        "s.choice_title",
        "ca.*",
        "SUM(s.record_count) AS total_records"
      ]
      
      group = [
        "s.agent_id",
        "s.choice_title"
      ]
      
      case @opts[:period_by]
      when 'daily'
        select << "ca.id AS col_key"
        group << "s.call_date"
      when 'weekly'
        select << "ca.stats_yearweek AS col_key"
        group << "ca.stats_yearweek"
      when 'monthly'
        select << "ca.stats_yearmonth AS col_key"
        group << "ca.stats_yearmonth"
      end
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_question_stats s"
      sql << "JOIN statistic_calendars ca ON ca.stats_date = s.call_date AND ca.stats_hour = -1"
      sql << "WHERE #{jn_where(get_where)}"
      sql << "GROUP BY #{jn_groups(group)}"      

      return jn_sql(sql)
    end
    
    def choice_list
      choices = []
      @questions.each do |qu|
        chos = qu.evaluation_answers.not_deleted.first.sorted_answer_list
        chos.each do |cho|
          unless choices.include?(cho["title"])
            choices << cho["title"]
          end
        end
      end
      return choices
    end
    
    def get_where
      whs = []
      whs << "s.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      whs << "s.evaluation_question_id IN (#{@greeting_codes.join(",")},0)"
      whs << "s.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      if @opts[:agent_name].present?
        whs << "EXISTS (SELECT 1 FROM users u WHERE #{sqlcond_user_name(@opts[:agent_name])} AND s.agent_id = u.id)"
      end
      if @opts[:group_name].present?
        whs << "EXISTS (SELECT 1 FROM groups g WHERE #{sqlcond_group_name(@opts[:group_name])} AND s.group_id = g.id)"
      end
      return whs
    end
    
    # end class
  end  
end

