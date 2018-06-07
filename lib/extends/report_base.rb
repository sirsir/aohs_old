require 'axlsx'

class ReportBase

  # class variable
  # @period_type, @sdate, @edate
  
  # spreadsheet xlsx
  # header
  
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
  
  # default / normal
  
  STYNMC_1 = {
    sz:         8,
    border:     Axlsx::STYLE_THIN_BORDER,
    alignment:  {
      vertical:     :top,
      wrap_text:    true
    }
  }
  
  private
  
  def percentx(a, b)
    
    c = a.to_f / b.to_f rescue 0
    return c * 100

  end
  
  def mg_cells(c1, c2, r1, r2=r1)
    
    # make list for merge cells
    
    cell_from = "#{Axlsx.col_ref(c1-1)}#{r1}"
    cell_to   = "#{Axlsx.col_ref(c2-1)}#{r2}"
    
    return [cell_from, cell_to].join(":")
  
  end

  def mg_row_cells(cols, row_at)
    
    # make list for merge cells in rows
    
    pos = []
    res = []
    
    cols.each_with_index {
      |c,i| pos << i+1 unless c.nil?
    }
    pos << cols.length + 1
    
    if pos.length > 1
      pos.each_with_index do |p,i|
        if i < (pos.length - 1) and pos[i+1] - pos[i] > 1
          res << mg_cells(pos[i],pos[i+1]-1,row_at)
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
  
  def xlsx_fname(name)
    
    fname = [name.downcase, FileName.current_dt].join("_")
    return include_tmp_dir([fname,".xlsx"].join)
  
  end

  def include_tmp_dir(fn)
    
    File.join(Settings.server.directory.tmp,fn)
 
  end
  
  def date_range_init
    
    # get range of date index and related info
    # for <stats_date_id> BETWEEN <a> AND <b>
    
    @show_month_lb = true
    @show_week_lb  = true
    @show_day_lb   = true
    
    d_rs  = []
  
    seles = [
        "MIN(id) AS s_id",
        "MIN(stats_date) AS s_dt",
        "MIN(stats_year) AS s_ye",
        "MIN(stats_yearmonth) AS s_ym",
        "MIN(stats_week) AS s_wk",
        "MAX(stats_date) AS s_mxd"
    ].join(",")
    
    grps  = []
    
    case @period_type
    when :daily
      grps << "stats_date"
    when :weekly
      grps << "stats_year, stats_week"
      @show_day_lb = false
    when :monthly
      grps << "stats_yearmonth"
      @show_day_lb = false
      @show_week_lb = false
    end
    
    scx   = StatisticCalendar.select(seles).daily
                             .date_between(@sdate, @edate)
                             .group(grps).all

    scx.each do |r|
      d_rs << {
        s_id:         r.s_id,
        s_date:       r.s_dt,
        s_yearmonth:  r.s_ym,
        s_week:       r.s_wk,
        s_drange:     {
          from: r.s_dt, to: r.s_mxd
        },
        s_key:        get_key_comp(r)
      }
    end
    
    scx = nil
    
    @dsel_range = d_rs
  
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
    
    return ((d > Date.today) ? Date.today : d)
  
  end
  
  def table_header
    
    yearmonths  = []
    weeks       = []
    days        = []
    
    @dsel_range.each do |r|
      yearmonths << {
        label:  r[:s_date].strftime("%b %Y"),
        ym:     r[:s_date].strftime("%Y-%m")
      }
      weeks << {
        label:  "#{r[:s_date].strftime("%W").to_i + 1}",
        y:      r[:s_date].strftime("%Y"),
        w:      r[:s_date].strftime("%W")
      }
      days << {
        label:  r[:s_date].strftime("%d (%a)"),
        d:      r[:s_date].strftime("%Y-%m-%d"),
        name:   r[:s_date].strftime("%a").downcase
      }
    end
    
    yearmonths  = calc_column_span(yearmonths)
    weeks       = calc_column_span(weeks)
    params      = params_list(days, weeks, yearmonths)
    
    return {
      yearmonth:  yearmonths.uniq,
      weeks:      weeks.uniq,
      days:       days,
      show_month: @show_month_lb,
      show_week:  @show_week_lb,
      show_day:   @show_day_lb,
      rowspan:    get_row_span_h,
      params:     params
    }
  
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
  
  def calc_column_span(ar)
    
    counts = Hash.new(0)
    
    ar.each {|r| counts[r[:label]] += 1 }
    ar = ar.uniq
    ar.each {|r| r[:span_count] = counts[r[:label]] }
    
    return ar
  
  end
  
  def get_row_span_h
    
    return [@show_month_lb,@show_week_lb,@show_day_lb].count { |x| x == true }
    
  end
  
  # sql
  
  def jn_select(a)
    
    return a.join(",")
  
  end
  
  def jn_where(a)
    
    return a.join(" AND ")
  
  end
  
  def jn_groups(a)
    
    return a.join(",")
    
  end

  def jn_orders(a)
    
    return a.join(",")
  
  end

  def jn_joins(a)
    
    return a.join(" ")
  
  end

  def jn_in(a)
    
    return a.uniq.join(",")
  
  end
  
  def avg_of(a, b)
    
    return a/b rescue 0
  
  end
  
  def sum_of(a, b)
    
    return a + b
  
  end

  def percent_of(a, b)
    
    c = a.to_f / b.to_f rescue 0
    return c * 100

  end

  def select_sql(sql)
    
    return ActiveRecord::Base.connection.select_all(sql)  
  
  end

end