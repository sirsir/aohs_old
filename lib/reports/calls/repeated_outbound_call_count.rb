module CallStatisticsReport
  class RepeatedOutboundCallCount < CallReportBase
    
    def initialize(opts={})
      set_params opts
      @opts[:report_name] = "Repeated Outbound Report"
      initial_report
      initial_header
    end
    
    def initial_header      
      cols = []
      cols << new_element("Customer Number (Dialed Number)", 1, 1)
      cols << new_element("Type of Phone Number", 1, 1)
      cols << new_element("Total Calls", 1, 1)
      cols << new_element("Max Calls/Day", 1, 1)
      cols << new_element("Average Calls/Days", 1, 1)
      add_header(cols, 0, 0)
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
      ds = []
      recs = select_sql(sql_data_repeat_outbound)  
      recs.each do |r|
        d = []
        d << r["number"]
        d << r["phone_type"]
        d << r["rec_count"]
        d << r["max_count"]
        d << r["rec_count"]/r["day_count"]
        ds << d
      end
      return ds
    end
    
    def sql_data_repeat_outbound
      code = PhonenoStatistic.statistic_type(:count,:outbound_dnis).id
      date_id = StatisticCalendar.get_id_range(@opts[:sdatetime],@opts[:edatetime])
      
      sql_a = []
      sql_a << "SELECT DATE(v.start_time) AS cdate, v.dnis, COUNT(0) AS v_count"
      sql_a << "FROM voice_logs v"
      sql_a << "WHERE v.call_direction = 'o' AND LENGTH(v.dnis) >= 4"
      sql_a << "AND v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      sql_a << "GROUP BY v.dnis, DATE(v.start_time)"
      sql_a = jn_sql(sql_a)
      
      sql_b = []
      sql_b << "SELECT c.stats_date, p.number, p.formatted_number, p.phone_type, SUM(p.total) AS total_records"
      sql_b << "FROM phoneno_statistics p"
      sql_b << "JOIN statistic_calendars c ON p.stats_date_id = c.id AND c.stats_hour = -1"
      sql_b << "WHERE p.stats_type IN (#{code}) AND p.phone_type NOT IN ('EXT','SPE','UNK')"
      sql_b << "AND c.stats_date BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      sql_b << "AND p.stats_date_id BETWEEN '#{date_id.first}' AND '#{date_id.last}'"
      sql_b << "GROUP BY p.stats_date_id, p.formatted_number"
      sql_b = jn_sql(sql_b)      
      
      sql = []
      sql << "SELECT s2.formatted_number AS number, s2.phone_type, MAX(s1.v_count) AS max_count, SUM(s1.v_count) AS rec_count, COUNT(0) AS day_count"
      sql << "FROM (#{sql_a}) s1 JOIN (#{sql_b}) s2"
      sql << "ON s1.cdate = s2.stats_date AND s1.dnis = s2.number"
      sql << "GROUP BY s2.formatted_number"
      sql << "ORDER BY SUM(s1.v_count) DESC"
      sql << "LIMIT #{@opts[:limit]}"

      return jn_sql(sql)
    end
    
  end
end