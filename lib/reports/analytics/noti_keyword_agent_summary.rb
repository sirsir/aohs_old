module AnalyticReport
  class NotiKeywordAgentSummary < AnalyticsReportBase
    
    def initialize(opts={})
      set_params opts
      set_option :report_name, "Keyword Alert Summary Report"
      initial_report
      initial_header
    end

    def initial_header
      get_keyword_list
      
      # row 1
      cols = []
      ucols = agent_info_columns
      gcols = group_info_columns
      xcols = [].concat(ucols).concat(gcols)
      xcols.each do |cl|
        cols << new_element(cl[:display_name], 1, 2)
      end
      cols << new_element("Keyword Count", 1, 2)
      cols << new_element("Type of Keyword", @keyword_types.length, 1)
      add_header(cols, 0, 0)
      
      # row 2
      cols = []
      @keyword_types.each do |ktype|
        cols << new_element(ktype.name, 1, 1)
      end
      add_header(cols, 1, 0)
    end
    
    def get_result
      ret = {
        data: get_data,
        headers: @headers
      }
      return ret
    end

    def to_xlsx
      return to_xlsx_file_default
    end
    
    private

    def get_keyword_list
      @keyword_types = KeywordType.where(notify_flag: "Y").order(:name).all.to_a
      @keyword_types_id = @keyword_types.map { |ktype| ktype.id }
    end
    
    def get_data
      data = []
      ucols = agent_info_columns
      gcols = group_info_columns
      ginfos = get_list_groupinfo_from_atl(:atl_log)
      data = []
      result = select_sql(sql_result)
      result.each do |rs|
        d = []
        u = get_user_info(rs["agent_id"])
        g = ginfos[rs["agent_id"].to_s] || {}
        ucols.each do |cl|
          d << u[cl[:name]]
        end
        gcols.each do |cl|
          d << g[cl[:name]]
        end
        d << rs["keyword_count"].to_i
        @keyword_types.each do |ktype|
          d << rs["col#{ktype.id}"].to_i
        end
        data << d
      end
      return data
    end
    
    def sql_result
      sql = []
      sql << "SELECT m.reference_id AS keyword_id, m.who_receive AS agent_id, k.name AS keyword_name,"
      @keyword_types.each do |ktype|
        sql << "SUM(IF(k.keyword_type_id=#{ktype.id},1,0)) AS col#{ktype.id},"
      end
      sql << "SUM(IF(m.read_flag=\"Y\",1,0)) AS read_count, COUNT(0) AS keyword_count"
      sql << "FROM message_logs m JOIN voice_logs v ON m.voice_log_id = v.id"
      sql << "JOIN keywords k ON m.reference_id = k.id"
      if case_of?([:aeoncol]) and (@opts[:group_name].present? or @opts[:section_name].present?)
        sql << "JOIN (#{sql_join_find_by_atl}) s2 ON m.who_receive = s2.agent_id"
      end
      sql << "WHERE m.message_type = \"Keyword\""
      sql << "AND v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      if @opts[:agent_name].present?
        sql << "AND " + sql_user_exist(@opts[:agent_name], "m.who_receive")
      end
      if (not case_of?([:aeoncol])) and @opts[:group_name].present?
        sql << "AND " + sql_user_exist_by_group(@opts[:group_name], "m.who_receive")
      end
      unless @keyword_types_id.empty?
        sql << "AND k.keyword_type_id IN (#{@keyword_types_id.join(",")})"
      end
      sql << "GROUP BY m.who_receive"
      return jn_sql(sql)
    end
    
    # end
  end
end