module EvaluationReport
  class AcsCallSummary < EvaluationReportBase

    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "QMS Summary Report"

      # get greeting question
      greeting_codes = ["GRET1"]
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
      cols << new_element("Item", 1, 1)
      cols << new_element("Total Records", 1, 1)
      if defined? @dsel_range and not @dsel_range.nil?
        dmyhdr = dmy_header
        dmyhdr[:days].each do |d|
          cols << new_element(d[:full_label], 1, 1) 
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
      rows = []
      row_at = 0
      
      result_calls = select_sql(sql_list_calls)
      result_priv = select_sql(sql_call_class)
      
      rows[row_at] = ["Duration", nil]
      @dsel_range.each { |d| rows[row_at] << nil }
      row_at += 1
      duration_range.each_with_index do |rx,i|
        next if i == 0
        rows[row_at] = []
        rows[row_at] << rx.display_name
        rows[row_at] << nil
        @dsel_range.each do |d|
          v = (result_calls.select { |x| d[:s_key] == x["col_key"] }).first
          rows[row_at] << (v.nil? ? 0 : v["col#{i}"])
        end
        rows[row_at][1] = sum_row(rows[row_at])
        row_at += 1
      end
      
      rows[row_at] = ["Greeting", nil]
      @dsel_range.each { |d| rows[row_at] << nil }
      row_at += 1
      result = select_sql(sql_list_choices(@greeting_codes))
      @greeting_choices.each do |cho|
        rows[row_at] = []
        rows[row_at] << cho
        rows[row_at] << nil
        @dsel_range.each do |d|
          v = (result.select { |x| d[:s_key] == x["col_key"] and cho == x["choice_title"] }).first
          rows[row_at] << (v.nil? ? 0 : v["total_records"])
        end
        rows[row_at][1] = sum_row(rows[row_at])
        row_at += 1
      end

      rows[row_at] = ["NG Word Usages", nil]
      @dsel_range.each { |d| rows[row_at] << nil }
      row_at += 1
      result = select_sql(sql_list_choices(@ng_codes))
      @ng_choices.each do |cho|
        rows[row_at] = []
        rows[row_at] << cho
        rows[row_at] << nil
        @dsel_range.each do |d|
          v = (result.select { |x| d[:s_key] == x["col_key"] and cho == x["choice_title"] }).first
          rows[row_at] << (v.nil? ? 0 : v["total_records"])
        end
        rows[row_at][1] = sum_row(rows[row_at])
        row_at += 1
      end

      rows[row_at] = ["Outbound Call", nil]
      @dsel_range.each { |d| rows[row_at] << nil }
      row_at += 1
      rows[row_at+0] = ["Call Outbound Volume",0]
      rows[row_at+1] = ["Grand Total Outbound",0]
      rows[row_at+2] = ["Short Call Duration",0]
      rows[row_at+3] = ["Call 4 Digits Number",0]
      rows[row_at+4] = ["Personal Call",0]
      @dsel_range.each do |d|
        v = (result_calls.select { |x| d[:s_key] == x["col_key"] }).first
        w = (result_priv.select { |x| d[:s_key] == x["col_key"] }).first
        v = Hash.new(0) if v.nil?
        w = Hash.new(0) if w.nil?
        rows[row_at+0] << v["total_records"]
        rows[row_at+1] << v["total_records"] - (v["short_call_count"].to_i + v["ext_count"].to_i)
        rows[row_at+2] << v["short_call_count"]
        rows[row_at+3] << v["ext_count"]
        rows[row_at+4] << w["total_reocrds"]
      end
      rows[row_at+0][1] = sum_row(rows[row_at+0])
      rows[row_at+1][1] = sum_row(rows[row_at+1])
      rows[row_at+2][1] = sum_row(rows[row_at+2])
      rows[row_at+3][1] = sum_row(rows[row_at+3])
      rows[row_at+4][1] = sum_row(rows[row_at+4])
      
      return rows
    end
    
    def sum_row(rows)
      return (rows.select { |r| r.is_a?(Integer) }).sum
    end
    
    def sql_list_choices(codes)
      sql = []
      
      select = [
        "s.choice_title",
        "SUM(s.record_count) AS total_records"
      ]
      
      group = [
        "s.choice_title",
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
      
      whs = []
      whs << "s.call_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      whs << "s.evaluation_question_id IN (#{codes.join(",")},0)"
      whs << "s.evaluation_plan_id IN (#{@opts[:form_id].join(",")})" unless @opts[:form_id].nil?
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_question_stats s"
      sql << "JOIN statistic_calendars ca ON ca.stats_date = s.call_date AND ca.stats_hour = -1"
      sql << "WHERE #{jn_where(whs)}"
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

    def sql_list_calls
      
      sql = []
      
      select = [
        "COUNT(0) AS total_records",
        "SUM(IF(LENGTH(v.dnis) <= 5,1,0)) AS ext_count",
        "SUM(IF(LENGTH(v.dnis) > 5 AND v.duration <= #{duration_range.first.upper_bound},1,0)) AS short_call_count"
      ]

      duration_range.each_with_index do |rx,i|
        next if i == 0
        if rx.upper_bound.nil?
          select << "SUM(IF(v.duration >= #{rx.lower_bound},1,0)) AS col#{i}"
        else
          select << "SUM(IF(v.duration BETWEEN #{rx.lower_bound} AND #{rx.upper_bound},1,0)) AS col#{i}"
        end
      end
      
      group = []
      
      case @opts[:period_by]
      when 'daily'
        select << "ca.id AS col_key"
        group << "v.call_date"
      when 'weekly'
        select << "ca.stats_yearweek AS col_key"
        group << "ca.stats_yearweek"
      when 'monthly'
        select << "ca.stats_yearmonth AS col_key"
        group << "ca.stats_yearmonth"
      end
      
      where = []
      where << "v.call_direction = 'o'"
      where << "v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM voice_logs v"
      sql << "JOIN statistic_calendars ca ON ca.stats_date = v.call_date AND ca.stats_hour = -1"
      sql << "WHERE #{jn_where(where)}"
      sql << "GROUP BY #{jn_groups(group)}"
      
      return jn_sql(sql)
    end
    
    def sql_call_class
      private_cates = CallCategory.only_private.all
      private_cates = private_cates.map { |c| c.id }
      sql = []
      
      select = [
        "COUNT(0) AS total_reocrds",
      ]
      
      group = []
      case @opts[:period_by]
      when 'daily'
        select << "ca.id AS col_key"
        group << "v.call_date"
      when 'weekly'
        select << "ca.stats_yearweek AS col_key"
        group << "ca.stats_yearweek"
      when 'monthly'
        select << "ca.stats_yearmonth AS col_key"
        group << "ca.stats_yearmonth"
      end
      
      where = []
      where << "v.call_direction = 'o'"
      where << "v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      where << "c.call_category_id IN (#{private_cates.join(",")})"
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM voice_logs v"
      sql << "JOIN call_classifications c ON c.voice_log_id = v.id"
      sql << "JOIN statistic_calendars ca ON ca.stats_date = v.call_date AND ca.stats_hour = -1"
      sql << "WHERE #{jn_where(where)}"
      sql << "GROUP BY #{jn_groups(group)}"
      return jn_sql(sql)
    end
    
    # end class
  end  
end

