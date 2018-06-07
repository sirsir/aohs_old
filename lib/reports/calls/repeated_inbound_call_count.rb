module CallStatisticsReport
  class RepeatedInboundCallCount < CallReportBase
    
    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Repeated Call Summary Report"
      initial_report
      initial_header
      log "options: #{@opts.inspect}"
    end
    
    def initial_header      
      cols = []
      cols << new_element("Customer Number (Caller Number)", 1, 1)
      cols << new_element("Type", 1, 1)
      cols << new_element("Total Calls", 1, 1)
      cols << new_element("Average Calls/Days")
      cols << new_element("Dialed Number", 1, 1)
      cols << new_element("Agents", 1, 1)
      add_header(cols, 0, 0)
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

    def get_data
      ds = []
      recs = select_sql(sql_data_repeat_outbound)  
      recs.each do |r|
        d = []
        d << r["number"]
        d << r["phone_type"]
        d << r["total"]
        d << r["total"]/r["ndays"]
        d << r["dniss"]
        d << get_agent_names(r["agents"].to_s.split(","))
        ds << d
      end
      return ds
    end
    
    def get_agent_names(ids)
      ids = ids.concat([0])
      return (User.where(id: ids).all.map { |u| u.display_name }).sort.join(", ")
    end
    
    def sql_data_repeat_outbound
      code = PhonenoStatistic.statistic_type(:count,:inbound_ani).id
      
      sql = []
      sql << "SELECT v.call_date, v.ani, GROUP_CONCAT(DISTINCT v.dnis) AS dniss, GROUP_CONCAT(DISTINCT v.agent_id) AS agents"
      sql << "FROM voice_logs v"
      sql << "WHERE v.call_direction = 'i'"
      sql << "AND v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      sql << "AND v.call_date IS NOT NULL"
      sql << "GROUP BY v.call_date, v.ani"
      sql1 = jn_sql(sql)
      
      sql = []
      sql << "SELECT p.number, COUNT(0) AS ndays, SUM(p.total) AS total, p.phone_type, v.dniss, GROUP_CONCAT(v.agents) AS agents"
      sql << "FROM phoneno_statistics p"
      sql << "JOIN dmy_calendars d ON p.stats_date_id = d.id"
      sql << "JOIN (#{sql1}) v ON v.call_date = d.stats_date AND v.ani = p.number"
      sql << "WHERE p.stats_type = #{code}"
      if @opts[:phone_type].present?
        sql << "AND p.phone_type = '#{PhoneNumber.phone_type(@opts[:phone_type])}'" 
      else
        sql << "AND p.phone_type <> 'SPE'"
      end
      sql << "GROUP BY p.number"
      sql << "ORDER BY p.total DESC"
      sql << "LIMIT #{@opts[:limit]}"
      
      return jn_sql(sql)
    end
    
  end
end