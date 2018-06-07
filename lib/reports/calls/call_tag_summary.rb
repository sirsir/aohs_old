module CallStatisticsReport
  class CallTagSummary < CallReportBase
    
    def initialize(opts={})
      set_params opts
      set_option :report_name, "Call Tag Summary Report"
      initial_report
      initial_header
    end
    
    def initial_header
      cols = []
      cols << new_element("Tag", 1, 1)
      cols << new_element("Category", 1, 1)
      cols << new_element("Total Calls", 1, 1)
      cols << new_element("Total Duration", 1, 1)
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
      data = []
      result = select_sql(sql_data)
      result.each do |rs|
        d = []
        d << rs["tag_name"]
        d << rs["tag_category_name"]
        d << rs["t_count"]
        d << StringFormat.format_sec(rs["t_duration"])
        data << d
      end
      return data
    end
    
    def sql_data
      sql = []      
      
      select = [
        "t.tag_id",
        "COUNT(0) AS rec_count",
        "SUM(duration) AS total_duration"
      ]
      
      where = []
      where << "v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"      
      where << "t.tag_id IN (#{@opts[:tag_id].join(",")})" if @opts[:tag_id].present?
      
      group = [
        "t.tag_id"
      ]
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM voice_logs v"
      sql << "JOIN taggings t ON v.id = t.tagged_id"
      sql << "WHERE #{jn_where(where)}"
      sql << "GROUP BY #{jn_groups(group)}"
      
      # count by tags
      sql_count = jn_sql(sql)
      
      sql = []
      
      select = [
        "tm.tag_category_name",
        "tm.name AS tag_name",
        "sqa.rec_count AS t_count",
        "sqa.total_duration AS t_duration"
      ]
      
      where = []
    
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM tags_maps tm"
      sql << "JOIN (#{sql_count}) sqa ON tm.id = sqa.tag_id"
      sql << "WHERE #{jn_where(where)}" unless where.empty?
 
      return jn_sql(sql)

    end
    
    # end class
  end
end