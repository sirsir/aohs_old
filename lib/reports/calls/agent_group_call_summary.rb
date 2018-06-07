module CallStatisticsReport
  class AgentGroupCallSummary < CallReportBase
    
    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Agent Call Summary Report"
      initial_report
      initial_header
      log "options: #{@opts.inspect}"
    end
    
    def initial_header
      row_cnt = @headers.length
      
      cols = []
      cols << new_element("Employee ID", 1, 1)
      cols << new_element("Agent Name", 1, 1)
      cols << new_element("Total Calls", 1, 1)
      
      if defined? @dsel_range and not @dsel_range.nil?
        dmyhdr = dmy_header
        dmyhdr[:days].each do |d|
          cols << new_element(d[:full_label], 1, row_cnt) 
        end
      end
      add_header(cols,0,0)
    end
    
    def get_result
      return {
        headers: @headers,
        data: get_data
      }
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
    
    private

    def group_report?   
      @opts[:row_by].to_sym == :group
    end
    
    def agent_report?
      @opts[:row_by].to_sym == :agent
    end
    
    def get_data
      data = []
      
      result = select_sql(sql_data)
      result.each do |rs|
        d = []
        if agent_report?
          u = get_user_info(rs["agent_id"])
          d << u[:employee_id]
          d << u[:display_name]
        else
          g = get_group_info(rs["group_id"])
          d << g[:display_name]
        end
        d << rs["tt_record"]
        if defined? @dsel_range and not @dsel_range.nil?
          @dsel_range.each_with_index do |dt,i|
            d << rs["col#{i}"].to_i
          end
        end
        data << d
      end
      
      return data    
    end
    
    def sql_data
      
      select = [
        "SUM(total) AS tt_record"
      ]
      
      group = []
      
      if agent_report?
        select << "agent_id"
        group << "agent_id"
      else
        select << "group_id"
        group << "group_id"
      end
      
      if defined? @dsel_range and not @dsel_range.nil?
        @dsel_range.each_with_index do |d,i|
          case @opts[:period_by]
          when 'daily'
            select << "SUM(IF(dc.id=#{d[:s_key]},total,0)) AS col#{i}"
          when 'weekly'
            select << "SUM(IF(dc.stats_yearweek=#{d[:s_key]},total,0)) AS col#{i}"
          when 'monthly'
            select << "SUM(IF(dc.stats_yearmonth=#{d[:s_key]},total,0)) AS col#{i}"
          end
        end
      end
      
      where = []
      
      stats = []
      if @opts[:call_direction].present?
        if @opts[:call_direction] == 'i'
          c = CallStatistic.statistic_type(:count,'inbound')
          stats << c.id
        else
          c = CallStatistic.statistic_type(:count,'outbound')
          stats << c.id
        end
      else
        c = CallStatistic.statistic_type(:count,'inbound')
        stats << c.id
        c = CallStatistic.statistic_type(:count,'outbound')
        stats << c.id
      end
      
      ra = StatisticCalendar.get_id_range(@opts[:sdate],@opts[:edate])
      where << "stats_date_id BETWEEN #{ra.first} AND #{ra.last}"
      where << "stats_type IN (#{jn_in(stats)})"
      if @opts[:agent_name].present?
        where << sql_user_exist(@opts[:agent_name],"agent_id")
      end
      if @opts[:group_name].present?
        where << sql_group_exist(@opts[:group_name],"group_id")        
      end
      
      sql = CallStatistic.select(jn_select(select))
                          .joins("JOIN dmy_calendars dc ON dc.id = stats_date_id")
                          .where(jn_where(where))
                          .group(jn_groups(group)).to_sql
      
      return sql
    end
    
    # end class    
  end
end