class EvaluationReportBase < ReportBase
  
  private
  
  def initial_report
    if timely_report?(@opts[:period_by])
      @period_type = @opts[:period_by].to_sym
      @sdate = @opts[:sdate]
      @edate = @opts[:edate]
      date_range_init
    end
    create_headers
  end
  
  def get_xlsx_titles
    rows = []
    # title
    row = [@opts[:report_name],nil]
    rows << row
    @start_at_row += rows.length
    return rows
  end
  
  def get_xlsx_filters
    rows = []
    # filter
    if @opts[:sdate].present?
      rows << ["Date Range","#{@opts[:sdate]} - #{@opts[:edate]}"]
    end
    if @opts[:form_name].present?
      rows << ["Form","#{@opts[:form_name]}"]
    end
    if @opts[:form_id].present?
      forms = EvaluationPlan.select(:name).where(id: @opts[:form_id]).all
      forms = forms.map { |f| f.name }
      rows << ["Form",forms.join(", ")]
    end
    if @opts[:group_name].present?
      rows << ["Group","#{@opts[:group_name]}"]
    end
    if @opts[:agent_name].present?
      rows << ["Agent","#{@opts[:agent_name]}"]
    end
    @start_at_row += rows.length
    return rows
  end
  
  def get_average_col_widths(col_count=2,min_width=10)
    cw = []
    col_count.times { |c| cw << min_width }
    return cw
  end
  
  def create_headers
    @th = TableHeader.new
    @headers = @th.headers
    @start_at_row = 0
  end

  def add_header(cols, row_at, col_at)    
    @th.add_header(cols,row_at,col_at)
    @headers = @th.headers
  end
  
  # prepare coloumn of question or category
  # to create table headers
  def get_column_criteria(find_for, question_ids=[])
    question_ids = [0] if question_ids.empty?
    sql = []
    case find_for
    when "group_question","category", "group"
      sql << "SELECT dsp.question_group_title AS col_title, dsp.question_group_id AS matched_id"
      sql << "FROM evaluation_question_display dsp"
      sql << "WHERE dsp.question_id IN (#{question_ids.join(",")})"
      sql << "GROUP BY dsp.question_group_id"
    else
      sql << "SELECT dsp.question_title AS col_title, dsp.question_id AS matched_id"
      sql << "FROM evaluation_question_display dsp"
      sql << "WHERE dsp.question_id IN (#{question_ids.join(",")})"
      sql << "GROUP BY dsp.question_id"
    end
    sql << "ORDER BY dsp.group_order_no, dsp.order_no"
    return select_sql(jn_sql(sql))
  end

  def duration_range
    return CallStatistic.statistic_type_ranges(:count,:all,:duration_range)
  end
  
  def get_xlsx_headers
    xls_spans = []
    start_at_row = ((defined? @start_at_row) ? @start_at_row : 0)
    headers, spans = @th.to_xlsx_headers
    spans.each do |s|
      # In excel start with 1
      rf = s[0] + 1 + start_at_row
      cf = s[1] + 1
      rt = s[2] + 1 + start_at_row
      ct = s[3] + 1
      xls_spans << mg_cells(cf,ct,rf,rt)
    end
    return headers, xls_spans
  end
  
  def get_grade(score, evaluation_plan_id)
    sql = "SELECT * FROM evaluation_grade_current "
    sql << "WHERE #{score.to_i} BETWEEN lower_bound AND upper_bound AND evaluation_plan_id = #{evaluation_plan_id} "
    sql << "LIMIT 1"
    rs = select_sql(sql)
    if rs.empty?
      return "Unk."
    else
      return rs.first["name"]
    end
  end

  def get_grade_v2(score, grade_list)
    grade_list = grade_list.to_s.split(",")
    grade_count = grade_list.inject(Hash.new(0)) {|h, v| h[v] += 1; h}
    xg = nil
    xv = 0
    grade_count.each do |g,v|
      xg = g if v > xv
    end
    sql = "SELECT * FROM evaluation_grades "
    sql << "WHERE #{score.to_i} BETWEEN lower_bound AND upper_bound AND evaluation_grade_setting_id = #{xg} "
    sql << "LIMIT 1"
    rs = select_sql(sql)
    if rs.empty?
      return "Unk."
    else
      return rs.first["name"]
    end
  end
  
  def get_evaluation_form_info(form_id)
    unless defined?(@lst_evaluation_forms)
      @lst_evaluation_forms = {}
    end
    if @lst_evaluation_forms[form_id.to_s].nil?
      @lst_evaluation_forms[form_id.to_s] = EvaluationPlan.where(id: form_id).first
    end
    return @lst_evaluation_forms[form_id.to_s]
  end
  
  # end class
end