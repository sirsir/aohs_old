module CallStatisticsReport
  class CallSummary < CallReportBase
    
    def initialize(opts={})
      set_params opts
      set_option :report_name, "Call Summary Report"
      initial_report
      initial_header
    end
    
    def initial_header
      # row 1
      cols = []
      cols << new_element("Date/Time", 1, 3)
      cols << new_element("Total Agent", 1, 3)
      cols << new_element("Inbound", inbound_stats_details.length + 5, 1)
      cols << new_element("Outbound", outbound_stats_details.length + 5, 1)
      add_header(cols, 0, 0)
      
      # row 2
      cols = []
      cols << new_element("Duration Range", inbound_stats_details.length, 1)
      cols << new_element("Total", 1, 2, link: true, searchkey: 'cd=i')
      cols << new_element("%", 1, 2)
      cols << new_element("Duration", 1, 2)
      cols << new_element("Max", 1, 2)
      cols << new_element("Avg", 1, 2)  
      cols << new_element("Duration Range", outbound_stats_details.length, 1)
      cols << new_element("Total", 1, 2, link: true, searchkey: 'cd=o')
      cols << new_element("%", 1, 2)
      cols << new_element("Duration", 1, 2)
      cols << new_element("Max", 1, 2)
      cols << new_element("Avg", 1, 2)
      add_header(cols, 1, 0)
      
      # row 3
      cols = []
      inbound_stats_details.each do |t|
        cols << new_element(t.display_name, 1, 1, link: true, searchkey: "cd=i|dur_fr=#{t.lower_bound}|dur_to=#{t.upper_bound}")
      end
      outbound_stats_details.each do |t|
        cols << new_element(t.display_name, 1, 1, link: true, searchkey: "cd=o|dur_fr=#{t.lower_bound}|dur_to=#{t.upper_bound}")
      end
      add_header(cols, 2, 0)
    end
    
    def get_result
      return {
        headers: @headers,
        data: get_data
      }
    end
    
    def to_xlsx
      return to_xlsx_file_default
    end
    
    private

    def get_data
      data = []
      result = select_sql(get_sql)  
      result.each do |r|
        # calc/sum/avg
        tt_d = sum_of(r["sum_inbound_duration"], r["sum_outbound_duration"])
        tt_c = sum_of(r["count_inbound"], r["count_outbound"])
        avg_inb_d = avg_of(r["sum_inbound_duration"], r["count_inbound"])
        avg_oub_d = avg_of(r["sum_outbound_duration"], r["count_outbound"])
        avg_d = avg_of(tt_d, tt_c)
        pct_inb   = percent_of(r["count_inbound"], tt_c)
        pct_oub   = percent_of(r["count_outbound"], tt_c)
        
        rs = []
        rs << get_display_dt(r)
        rs << r["user_count"].to_i
        # inbound
        inbound_stats_details.each do |rx|
          rs << r[rx.label]
        end
        rs << r["count_inbound"]
        rs << StringFormat.pct_format(pct_inb)
        rs << duration_fmt(r["sum_inbound_duration"])
        rs << duration_fmt(r["max_inbound_duration"])
        rs << duration_fmt(avg_inb_d)
        # outbound
        outbound_stats_details.each do |rx|
          rs << r[rx.label]
        end
        rs << r["count_outbound"]
        rs << StringFormat.pct_format(pct_oub)
        rs << duration_fmt(r["sum_outbound_duration"])
        rs << duration_fmt(r["max_outbound_duration"])
        rs << duration_fmt(avg_oub_d)
        
        data << rs
      end
      
      return data
    end
    
    def get_sql
      selects, groups, orders, wheres = get_selections
      sql = CallStatistic.select(jn_select(selects))
                          .joins(:statistic_calendar)
                          .where(jn_where(wheres))
                          .group(jn_groups(groups))
                          .order(jn_orders(orders)).to_sql
      return sql
    end
    
    def get_selections
      selects = []
      groups  = []
      orders  = []
      stats   = []
      wheres  = []
      ta      = StatisticCalendar.table_name
      tc      = CallStatistic.table_name
      
      case true
      when daily_report?
        selects << "#{ta}.stats_date"
      when weekly_report?
        selects << "#{ta}.stats_year"
        selects << "#{ta}.stats_week"
      when monthly_report?
        selects << "#{ta}.stats_yearmonth"
      end
      
      groups = selects.clone
      orders = selects.clone.map { |s| "#{s} DESC" }
      selects << "COUNT(DISTINCT agent_id) AS user_count"
      
      # inbound statistics
      c = CallStatistic.statistic_type(:count,'inbound')      
      selects << "SUM(IF(stats_type = #{c.id},total,0)) AS #{c.label}"
      stats   << c.id
      c = CallStatistic.statistic_type(:sum,'inbound_duration')      
      selects << "SUM(IF(stats_type = #{c.id},total,0)) AS #{c.label}"
      stats   << c.id
      c = CallStatistic.statistic_type(:max,'inbound_duration')      
      selects << "MAX(IF(stats_type = #{c.id},total,0)) AS #{c.label}"
      stats   << c.id
      ranges = CallStatistic.statistic_type_ranges(:count, :inbound, :duration_range)
      ranges.each do |r|
        selects << "SUM(IF(stats_type = #{r.id},total,0)) AS #{r.label}"
        stats   << r.id
      end
      
      # outbound statistics
      c = CallStatistic.statistic_type(:count,'outbound')      
      selects << "SUM(IF(stats_type = #{c.id},total,0)) AS #{c.label}"
      stats   << c.id
      c = CallStatistic.statistic_type(:sum,'outbound_duration')      
      selects << "SUM(IF(stats_type = #{c.id},total,0)) AS #{c.label}"
      stats   << c.id
      c = CallStatistic.statistic_type(:max,'outbound_duration')      
      selects << "MAX(IF(stats_type = #{c.id},total,0)) AS #{c.label}"
      stats   << c.id
      ranges = CallStatistic.statistic_type_ranges(:count, :outbound, :duration_range)
      ranges.each do |r|
        selects << "SUM(IF(stats_type = #{r.id},total,0)) AS #{r.label}"
        stats << r.id
      end
      
      # get date index
      ra = StatisticCalendar.get_id_range(@opts[:sdate],@opts[:edate])
      wheres << "stats_date_id BETWEEN #{ra.first} AND #{ra.last}"
      wheres << "stats_type IN (#{jn_in(stats)})"
      if @opts[:agent_name].present?
        wheres << sql_user_exist(@opts[:agent_name],"agent_id")
      end
      if @opts[:group_name].present?
        wheres << sql_group_exist(@opts[:group_name],"group_id")        
      end
      
      return selects, groups, orders, wheres
    end
    
    def get_display_dt(r)
      case true
      when daily_report?
        return r["stats_date"].strftime("%Y-%m-%d")
      when weekly_report?
        xweek = r["stats_week"]
        xyear = r["stats_year"].to_i
        xdate = Date.commercial(xyear,xweek)
        return "#{xdate.strftime("%d/%b/%Y")} - #{xdate.end_of_week.strftime("%d/%b/%Y")}"
      when monthly_report?
        xym = Date.parse(r["stats_yearmonth"].to_s << "01").strftime("%b/%Y")
        return xym
      else
        return "E"
      end
    end

  end
end