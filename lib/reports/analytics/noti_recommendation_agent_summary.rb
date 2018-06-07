module AnalyticReport
  class NotiRecommendationAgentSummary < AnalyticsReportBase
    
    def initialize(opts={})
      set_params opts
      set_option :report_name, "Recommendation Summary Report"
      initial_report
      initial_header
    end
    
    def initial_header
      get_list_of_faq
      
      # row 1
      cols = []
      ucols = agent_info_columns
      gcols = group_info_columns
      xcols = [].concat(ucols).concat(gcols)
      xcols.each do |cl|
        cols << new_element(cl[:display_name], 1, 3)
      end
      cols << new_element("Total Displayed Message", 1, 3)
      @faq_ques.each do |fq|
        cols << new_element(fq[:question], @faq_anss[fq[:id].to_s].length + 1, 1)
      end
      add_header(cols,0,0)
      
      # row 2
      cols = []
      @faq_ques.each do |fq|
        next if  @faq_anss[fq[:id].to_s].length <= 0
        cols << new_element("Displayed Count", 1, 2)
        cols << new_element("Clicked Count", @faq_anss[fq[:id].to_s].length, 1)
      end
      add_header(cols,1,0)
      
      # row 3
      cols = []
      @faq_ques.each do |fq|
        @faq_anss[fq[:id].to_s].each do |fa|
          cols << new_element(fa[:content], 1, 1)
        end
      end
      add_header(cols,2,0)
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
    
    def get_data
      data = []
      ucols = agent_info_columns
      gcols = group_info_columns
      
      result = select_sql(sql_result)
      # conver result to hash
      result_u = {}
      result_f = {}
      result_a = {}
      result.each do |rs|
        k1 = [rs["agent_id"]].join("-")
        k2 = [rs["agent_id"],rs["faq_id"],rs["ans_id"]].join("-")
        k3 = [rs["agent_id"],rs["faq_id"]].join("-")
        result_u[k1] = { count: 0 } if result_u[k1].nil?
        result_u[k1][:count] += rs["r_count"].to_i
        result_f[k2] = { count: 0 } if result_f[k2].nil?
        result_f[k2][:count] += rs["r_count"].to_i
        result_a[k3] = { count: 0 } if result_a[k3].nil?
        result_a[k3][:count] += rs["r_count"].to_i
      end
      
      ginfos = get_list_groupinfo_from_atl(:atl_log)
      
      result_u.each_pair do |u_id, ra|
        d = []
        u = get_user_info(u_id)
        g = ginfos[u_id.to_s] || {}
        ucols.each do |cl|
          d << u[cl[:name]]
        end
        gcols.each do |cl|
          d << g[cl[:name]]
        end
        d << number_fmt(ra[:count])
        @faq_ques.each do |fq|
          k3 = [u_id,fq[:id]].join("-")
          d << (result_a[k3].nil? ? 0 : number_fmt(result_a[k3][:count]))
          @faq_anss[fq[:id].to_s].each do |fa|
            k2 = [u_id,fq[:id],fa[:id]].join("-")
            d << (result_f[k2].nil? ? 0 : number_fmt(result_f[k2][:count]))
          end
        end
        data << d
      end
      
      return data
    end
    
    def sql_result
      sql = []
      sql << "SELECT m.who_receive AS agent_id, m.reference_id AS faq_id, IFNULL(m.item_id,0) AS ans_id, COUNT(0) AS r_count"
      sql << "FROM message_logs m"
      sql << "JOIN voice_logs v ON m.voice_log_id = v.id"
      sql << "JOIN faq_questions f ON f.id = m.reference_id"
      if case_of?([:aeoncol]) and (@opts[:group_name].present? or @opts[:section_name].present?)
        sql << "JOIN (#{sql_join_find_by_atl}) s2 ON m.who_receive = s2.agent_id"
      end
      sql << "WHERE m.message_type = 'Recommendation'"
      sql << "AND v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      if @opts[:agent_name].present?
        sql << "AND " + sql_user_exist(@opts[:agent_name], "m.who_receive")
      end
      if (not case_of?([:aeoncol])) and @opts[:group_name].present?
        sql << "AND " + sql_user_exist_by_group(@opts[:group_name], "m.who_receive")
      end
      sql << "GROUP BY m.who_receive, m.reference_id, m.item_id"
      sql = jn_sql(sql)
      return sql
    end
    
    def get_list_of_faq
      #
      # to find and prepare list of FAQs.
      #
      @faq_ques = []
      @faq_anss = {}
      
      sql = []
      sql << "SELECT fq.id AS que_id, fq.question, fa.id AS ans_id, fa.content"
      sql << "FROM faq_questions fq JOIN faq_answers fa ON fq.id = fa.faq_question_id"
      sql << "WHERE fq.flag <> 'D' AND fa.flag <> 'D'"
      sql << "GROUP BY fq.id, fa.id"
      sql << "ORDER BY fq.question, fa.id"
      sql = jn_sql(sql)
      result = select_sql(sql)
      result.each do |rs|
        q_id = rs["que_id"].to_s
        if @faq_anss[q_id].nil?
          @faq_ques << { id: rs["que_id"], question: StringFormat.html_sanitizer(rs["question"]) }
          @faq_anss[q_id] = [{ id: rs["ans_id"], content: StringFormat.html_sanitizer(rs["content"]) }]
        else
          @faq_anss[q_id] << { id: rs["ans_id"], content: StringFormat.html_sanitizer(rs["content"]) }
        end
      end
    end
    
    # end
  end
end