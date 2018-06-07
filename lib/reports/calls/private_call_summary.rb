module CallStatisticsReport
  class PrivateCallSummary < CallReportBase
    def initialize(opts={})
      @opts = opts
      @opts[:report_name] = "Private Call Summary"
      initial_report
      initial_header
      log "options: #{@opts.inspect}"
    end
    
    def initial_header
      cols = []
      cols << new_element("Phone Number", 1, 1)
      cols << new_element("Type", 1, 1)
      cols << new_element("Number of Calls", 1, 1)
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
      data = []
      result = select_sql(sql_data)
      result.each do |rs|
        r = []
        r << rs["number"]
        t = TelephoneInfo.number_type(rs["number_type"])
        unless t.nil?
          r << t[:name]
        else
          r << ""
        end
        r << rs["total_calls"].to_i
        data << r
      end
      return data
    end
    
    def sql_data
      sql = []

      sql << "SELECT t.number, t.number_type, SUM(p.total) AS total_calls"
      sql << "FROM telephone_infos t"
      sql << "JOIN phoneno_statistics p ON t.number = p.formatted_number"
      sql << "JOIN dmy_calendars d ON p.stats_date_id = d.id"
      sql << "WHERE t.number_type IN ('p','f')"
      sql << "AND d.stats_date BETWEEN '#{@opts[:sdate]}' AND '#{@opts[:edate]}'"
      sql << "GROUP BY t.number"

      return jn_sql(sql)
    end
    
    # end class
  end
end
