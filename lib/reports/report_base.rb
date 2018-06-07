require 'axlsx'

class ReportBase

  #################################################################################################################################
  # constant
  #################################################################################################################################
  
  S_SPACE = " "
  S_COMMA = ","
  S_ANDOP = " AND "
  S_OROPR = " OR "
  F_XLSX  = ".xlsx"
  
  # style sheet for xlsx
  # - header and title
  # - filterer / selection 
  # - table columns header
  # - table body
  # - table footer
  
  # style - title
  
  STYHDR_0 = {
    sz:         10,
    bg_color:   "FFF8DC",
    fg_color:   "000000",
    b:          true,
    border:     Axlsx::STYLE_THIN_BORDER,
    alignment:  {
      horizontal:   :left,
      vertical:     :center
    }
  }

  # style - table header columns
  
  STYHDR_1 = {
    sz:         8,
    bg_color:   "4F94CD",
    fg_color:   "EDEDED",
    b:          true,
    border:     Axlsx::STYLE_THIN_BORDER,
    alignment:  {
      horizontal:   :center,
      vertical:     :center
    }
  }
  
  # style - filters
  
  STYHDR_2 = {
    sz:         8,
    bg_color:   "FFF8DC",
    fg_color:   "000000",
    b:          true,
    border:     Axlsx::STYLE_THIN_BORDER,
    alignment:  {
      horizontal:   :left,
      vertical:     :center
    }
  }
  
  # style - body/details
  
  STYNMC_1 = {
    sz:         8,
    border:     Axlsx::STYLE_THIN_BORDER,
    alignment:  {
      vertical:     :top,
      wrap_text:    true
    }
  }

  # style - footer
  
  STYFOT_1 = {
    sz:         8,
    bg_color:   "E0E0E0",
    fg_color:   "000000",
    b:          true,
    border:     Axlsx::STYLE_THIN_BORDER,
    alignment:  {
      horizontal:   :left,
      vertical:     :center
    }
  }
  
  # - end style
  
    
  private

  #################################################################################################################################
  # option and prop
  #################################################################################################################################

  def set_params(params)
    @opts = params
    log "input params: #{@opts.inspect}"
  end
  
  def set_option(key_name, value)
    if defined? @opts
      @opts[key_name] = value
    end
  end
  
  def case_of?(name)
    # check function option based on customer
    names = (name.is_a?(Array) ? name : [name])
    if names.include?(Settings.site.codename.to_sym)
      return true
    end
    return false
  end

  def include_tmp_dir(fname)
    tmp_dir = Settings.server.directory.tmp
    WorkingDir.make_tmpdir(tmp_dir)
    return File.join(tmp_dir, fname)
  end
  
  
  
  #################################################################################################################################
  # condition and parameters
  #################################################################################################################################
  
  def by_period?
    return (defined? @enable_period_column and @enable_period_column)
  end
  
  def timely_report?(name="none")
    name = (name.blank? ? "none" : name)
    return [:daily, :weekly, :monthly].include?(name.to_sym)
  end
  
  def daily_report?
    return (@period_type == :daily)  
  end
  
  def weekly_report?
    return (@period_type == :weekly)
  end
  
  def monthly_report?
    return (@period_type == :monthly)
  end 
  
  def has_date_range?
    return (defined? @dsel_range and (not @dsel_range.nil?))  
  end
  
  
  
  #################################################################################################################################
  # excel
  #################################################################################################################################
  
  def set_sheet_style(ws)
    # xlsx style sheet
    wt = ws.styles
    return {
      title:    wt.add_style(STYHDR_0),
      filter:   wt.add_style(STYHDR_2),
      thead:    wt.add_style(STYHDR_1),
      all:      wt.add_style(STYNMC_1),
      tfoot:    wt.add_style(STYFOT_1),
      default:  wt.add_style(STYNMC_1),
    }
  end
  
  def mg_cells(c1, c2, r1, r2=r1)
    # create merged cell info
    # example: A1:A2, A1:B1
    cell_from = "#{Axlsx.col_ref(c1-1)}#{r1}"
    cell_to   = "#{Axlsx.col_ref(c2-1)}#{r2}"
    return [cell_from, cell_to].join(":")
  end

  def new_element(v, cspan=1, rspan=1, *opts)
    # create cell object for html and xlsx
    opts = opts.first || {}
    return {
      title: v,
      colspan: cspan,
      rowspan: rspan,
      clickable: (opts[:link] == true),
      searchkey: opts[:searchkey]
    }
  end
  
  def mg_row_cells(cols, row_at)
    # auto merge cells in row which is nil (no value)
    # example: ['A',nil,nil,'B']
    pos = []
    res = []
    cols.each_with_index {
      |c,i| pos << i + 1 unless c.nil?
    }
    pos << cols.length + 1
    if pos.length > 1
      pos.each_with_index do |p,i|
        if (i < (pos.length - 1)) and (pos[i+1] - pos[i] > 1)
          res << mg_cells(pos[i], pos[i+1]-1 , row_at)
        end
      end
    end
    return res
  end

  def mk_cells(n,v=nil)
    # make n cells
    cells = []
    n.times { cells << v }
    return cells
  end

  def calc_column_span(ar)
    counts = Hash.new(0)
    ar.each {|r| counts[r[:label]] += 1 }
    ar = ar.uniq
    ar.each {|r| r[:span_count] = counts[r[:label]] }
    return ar
  end
  
  def xlsx_fname(name)
    new_fname = FileName.sanitize(name)
    new_fname = [new_fname, FileName.current_dt].join("_")
    return include_tmp_dir([new_fname, F_XLSX].join)
  end



  #################################################################################################################################
  # export report to xlsx
  #################################################################################################################################

  def get_xlsx_file_titles
    rows = []
    # title
    row = [@opts[:report_name],nil]
    rows << row
    @start_at_row += rows.length
    return rows
  end

  def get_xlsx_file_filters
    rows = []
    # filter
    if @opts[:sdate].present?
      rows << ["Date Range","#{@opts[:sdate]} - #{@opts[:edate]}"]
    end
    if @opts[:group_name].present?
      rows << ["Group","#{@opts[:group_name]}"]
    end
    if @opts[:agent_name].present?
      rows << ["Agent","#{@opts[:agent_name]}"]
    end
    if @opts[:call_direction].present?
      rows << ["Call Direction","#{((@opts[:call_direction] == 'i') ? 'Inbound' : 'Outbound')}"]
    end
    @start_at_row += rows.length
    return rows
  end

  def get_xlsx_file_headers
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
  
  def to_xlsx_file_default
    wb = Axlsx::Package.new
    ws = wb.workbook.add_worksheet(name: 'report')
    style = set_sheet_style(ws)      
    
    get_xlsx_file_titles.each_with_index do |row,i|
      ws.add_row row, style: style[:title]
    end
    
    get_xlsx_file_filters.each_with_index do |row,i|
      ws.add_row row, style: style[:filter]
    end
    
    headers, spans = get_xlsx_file_headers
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
    
    if defined? @footer
      row = @footer[:data]
      ws.add_row row, style: style[:tfoot]
    end
    
    calculate_xlsx_column_widths(headers.last.length).each_with_index do |w,i|
      ws.column_info[i].width = w
    end
    
    @out_fpath = xlsx_fname(@opts[:report_name])
    wb.serialize(@out_fpath)

    return {
      path: @out_fpath
    } 
  end
  
  def calculate_xlsx_column_widths(col_count=2,min_width=10)
    cw = []
    col_count.times { |c| cw << min_width }
    return cw
  end
  
  

  #################################################################################################################################
  # date and time info
  #################################################################################################################################
  
  def date_range_init
    # get range of date index and related info
    # for <stats_date_id> BETWEEN <a> AND <b>
    @enable_period_column = true
    # label flag
    @show_month_lb = true
    @show_week_lb  = true
    @show_day_lb   = true
    
    select = [
      "MIN(id) AS s_id",
      "MIN(stats_date) AS s_dt",
      "MIN(stats_year) AS s_ye",
      "MIN(stats_yearmonth) AS s_ym",
      "MIN(stats_week) AS s_wk",
      "MAX(stats_date) AS s_mxd"
    ]
    
    group_by = []
    case @period_type
    when :daily
      group_by << "stats_date"
    when :weekly
      group_by << "stats_year, stats_week"
      @show_day_lb = false
    when :monthly
      group_by << "stats_yearmonth"
      @show_day_lb = false
      @show_week_lb = false
    end
    
    scx   = StatisticCalendar.select(jn_select(select)).daily.date_between(@sdate, @edate).group(jn_groups(group_by)).order_by_default.all
    
    @dsel_range  = []
    scx.each do |r|
      s_yw = (r.s_ye * 100) + r.s_wk
      @dsel_range << {
        s_id: r.s_id,
        s_date: r.s_dt,
        s_date_str: r.s_dt.strftime("%Y-%m-%d"),
        s_yearmonth: r.s_ym,
        s_yearweek: s_yw,
        s_week: r.s_wk,
        s_drange: {
          from: ((r.s_dt < @sdate) ? @sdate : r.s_dt),
          to: ((r.s_mxd > @edate) ? @edate : r.s_mxd)
        },
        s_key: get_key_comp(r)
      }
    end
    scx = nil
  end
  
  def get_key_comp(r)
    case @period_type
    when :daily
      return r.s_id
    when :weekly
      return (r.s_ye * 100) + r.s_wk
    when :monthly
      return r.s_ym
    end
  end
  
  def limit_end_date(d)
    today = Date.today
    return ((d > today) ? today : d)
  end
  
  def working_hours
    hrx = []
    hr_range = Settings.calendar.work_time
    hr_range = (hr_range.map { |h| Time.parse(h).hour }).sort
    w_hrs = (hr_range.first..hr_range.last).to_a
    w_hrs.each_with_index do |hr, i|
      # add first
      if i == 0 and hr > 0
        hrx << {
          title: "< #{hr}:00",
          hour: hr,
          sql_cond: "< #{hr}"
        }
      end
      # add normal
      hrx << {
        title: "#{hr}:00 - #{hr}:59",
        hour: hr,
        sql_cond: "= #{hr}"
      }
      # add last
      if i >= w_hrs.length - 1 and hr < 23
        hrx << {
          title: " >= #{hr+1}:00",
          hour: hr,
          sql_cond: "> #{hr}"
        }
      end
    end
    return hrx
  end
  
  # header d,w,m
  # to create header details for daily, weekly, monthly #
  
  def dmy_header
    return build_dmy_headers_info  
  end
  
  def build_dmy_headers_info #table_header
    yearmonths = []
    weeks = []
    days = []
    
    @dsel_range.each do |r|
      yearmonths << {
        label: r[:s_date].strftime("%b %Y"),
        ym: r[:s_date].strftime("%Y-%m")
      }
      weeks << {
        label: r[:s_date].strftime("%W"),
        y: r[:s_date].strftime("%Y"),
        w: r[:s_date].strftime("%W")
      }
      days << {
        label: r[:s_date].strftime("%d (%a)"),
        d: r[:s_date].strftime("%Y-%m-%d"),
        full_label: date_full_label(r),
        name: r[:s_date].strftime("%a").downcase
      }
    end
    
    yearmonths  = calc_column_span(yearmonths)
    weeks = calc_column_span(weeks)
    params = params_list(days, weeks, yearmonths)
    
    return {
      yearmonth: yearmonths.uniq,
      weeks: weeks.uniq,
      days: days,
      show_month: @show_month_lb,
      show_week: @show_week_lb,
      show_day: @show_day_lb,
      rowspan: get_row_span_h,
      params: params
    }
  end 
  
  def date_full_label(r)
    # label for display in table (reports)
    # single row 
    case @period_type
    when :daily
      return r[:s_date].strftime("%Y-%m-%d")
    when :weekly
      a = r[:s_drange][:from].strftime("%d/%b")
      b = r[:s_drange][:to].strftime("%d/%b")
      return "#{a} - #{b}"
    when :monthly
      return r[:s_date].strftime("%b/%Y")
    end
    return nil
  end
  
  def params_list(dx, wx, ymx)  
    params = []
    if @show_day_lb
      params = dx.clone
    elsif @show_week_lb
      params = wx.clone
    elsif @show_month
      params = ymx.clone
    end
    return params
  end
    
  def get_row_span_h
    return [@show_month_lb,@show_week_lb,@show_day_lb].count { |x| x == true }
  end



  #################################################################################################################################
  # display and selection
  #################################################################################################################################
  
  def show_nodata_record?
    #
    # for report which is group by agent/user
    # may show no data also
    #
    return case_of?([:aeoncol])
  end
  
  

  #################################################################################################################################
  # get infos
  #################################################################################################################################
  
  def get_user_info(user_id, group_id=nil)
    @ds_users = {} unless defined? @ds_users
    user_id = user_id.to_s
    if @ds_users[user_id].nil?
      u = {
        display_name: (user_id.to_i <= 0 ? "" : "Unknown")
      }
      usr = User.where(id: user_id).first
      unless usr.nil?
        u[:display_name]  = usr.display_name
        u[:agent_name]    = usr.display_name
        g = usr.group_info
        u[:group_id]      = usr.group_id
        u[:group_name]    = usr.group_name
        u[:employee_id]   = usr.employee_id
        pa = g.parent_groups
        unless pa.blank?
          pa.each do |g|
            next if g.group_type.blank?
            key = [g.group_type.downcase,"name"].join("_").to_sym
            u[key] = g.group_name
          end
        end
        group_leaders_list.each do |ld|
          lx = g.leader_info(ld.member_type).leader_info
          u[ld.display_name] = lx.display_name 
        end
      end
      @ds_users[user_id] = u
    end
    return @ds_users[user_id]
  end

  def get_group_info(group_id)
    dsg = {
      id: 0,
      display_name: "Unknown"      
    }
    g = Group.where(id: group_id).first
    unless g.nil?
      dsg = {
        id: g.id,
        display_name: g.display_name
      }
      group_leaders_list.each do |ld|
        lx = g.leader_info(ld.member_type).leader_info
        dsg[ld.display_name] = lx.display_name 
      end
    end
    return dsg
  end
  
  def group_leaders_list
    unless defined? @ds_leaders
      @ds_leaders = GroupMemberType.all_types
    end
    return @ds_leaders
  end

  def get_full_list_agent
    # find possible all agents to show in reports
    # report may need to show even if no data
    result = []
    if case_of?([:aeoncol])
      result = get_list_groupinfo_from_atl(:atl_log)
    end
    result_ids = result.keys.map { |x| x.to_s }
    return result_ids, result
  end
  
  
  
  #################################################################################################################################
  # display columns
  #################################################################################################################################
  
  def agent_info_columns
    # default column for agent information
    # get latest info
    ucols = []
    ucols << { name: :employee_id,  display_name: "Employee ID" }
    ucols << { name: :operator_id,  display_name: "Operator ID" }
    ucols << { name: :agent_name,   display_name: "Agent's Name" }
    return ucols
  end
  
  def group_info_columns
    gcols = []
    if case_of?([:aeoncol])
      gcols << { name: :team_name, display_name: 'Group' }
      gcols << { name: :performance_group_name, display_name: 'Performance Group' }
      gcols << { name: :section_id, display_name: 'Section ID' }
    else
      gcols << { name: :group_name, display_name: 'Group' }
    end
    return gcols
  end
  
  def get_group_columns
    # To provide list of columns of group to show in the report
    # example: branch, department, group, etc.
    display_list = Settings.group.report_group_columns
    unless display_list.blank?
      display_list = display_list.map { |x|
        { name: x.first, display_name: x.last, title: x.last, field_name: [x.first,'name'].join("_").to_sym }
      }
    else
      display_list = []
    end
    return display_list
  end
  
  
  
  #################################################################################################################################
  # value and formatting
  #################################################################################################################################
  
  def duration_fmt(secs=0)
    if defined? @opts
      case @opts[:duration_fmt]
      when :hour
        return (secs.to_f/(60.0*60.0)).round(2)
      when :second
        return secs
      end
    end
    return StringFormat.duration_reporting_format(secs)
  end
  
  def number_fmt(n=0)
    return n.to_i
  end
  
  def floating_fmt(n=0)
    return sprintf("%0.2f",n.to_f)
  end
  
  
  
  #################################################################################################################################
  # sql query
  #################################################################################################################################
  
  def sql_user_exist(name, field)
    sql = []
    sql << "SELECT 1 FROM users us"
    sql << "WHERE us.id = #{field}"
    sql << "AND (us.full_name_en LIKE '%#{name}%' OR us.full_name_th LIKE '#{name}')"
    return "EXISTS (#{jn_sql(sql)})"
  end
  
  def sql_user_exist_by_group(group, field)
    sql = []
    sql << "SELECT 1 FROM users us"
    sql << "JOIN group_members gm ON us.id = gm.user_id"
    sql << "JOIN groups gr ON gr.id = gm.group_id AND gm.member_type = 'M'"
    sql << "WHERE gr.name LIKE '%#{group}%'"
    sql << "AND us.id = #{field}"
    return "EXISTS (#{jn_sql(sql)})"
  end
  
  def sql_group_exist(group, field)
    sql = []
    sql << "EXISTS (SELECT 1"
    sql << "FROM groups gr"
    sql << "WHERE gr.name LIKE '%#{group}%'"
    sql << "AND gr.id = #{field})"
    return jn_sql(sql)
  end
  
  def sqlcond_user_name(name)
    # where by username, name
    return "(full_name_en LIKE '%#{name}%' OR full_name_th LIKE '%#{name}%')"
  end
  
  def sqlcond_group_name(name)
    # where by group name
    return "(name LIKE '%#{name}%' OR short_name LIKE '%#{name}%')"
  end
  
  
  
  #################################################################################################################################
  # calculation
  #################################################################################################################################

  def avg_of(a, b)
    begin
      return a/b
    rescue
      return 0
    end
  end
  
  def sum_of(a, b)
    return a + b
  end

  def percent_of(a, b)
    c = a.to_f / b.to_f rescue 0
    return c * 100
  end

  def percentx(a, b)
    c = a.to_f / b.to_f rescue 0
    return c * 100
  end
    
  
  
  #################################################################################################################################
  # query builder
  #################################################################################################################################
  
  def jn_sql(a)
    return a.join(S_SPACE)
  end
  
  def jn_select(a)
    return a.join(S_COMMA)
  end
  
  def jn_where(a)
    return a.join(S_ANDOP)
  end
  
  def jn_or(a)
    return a.join(S_OROPR)
  end
  
  def jn_groups(a)
    return a.join(S_COMMA)
  end
  
  def jn_group(a)
    return jn_groups(a)
  end
  
  def jn_orders(a)
    return a.join(S_COMMA)
  end

  def jn_joins(a)
    return a.join(S_SPACE)
  end

  def jn_in(a)
    return a.uniq.join(S_COMMA)
  end
  
  def sql_valmap(v)
    if v.is_a?(Array)
      return (v.map { |x| "'#{x}'" }).join(",")
    end
    return v
  end



  #################################################################################################################################
  # sql exec
  #################################################################################################################################
  
  def select_sql(sql)
    begin
      return ActiveRecord::Base.connection.select_all(sql)
    rescue => e
      log "error while query - #{sql}"
    end
    return []
  end
  
  
  
  #################################################################################################################################
  # logging
  #################################################################################################################################
  
  def current_class_name
    return self.class.name.gsub("::","#")
  end
  
  def log(msg, type=:info)
    case type
    when :error
      Rails.logger.error "#{current_class_name}, #{msg}"
    else
      Rails.logger.info "#{current_class_name}, #{msg}"
    end
  end
  
end