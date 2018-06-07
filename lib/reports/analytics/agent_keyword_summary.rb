module AnalyticReport
  class AgentKeywordSummary < AnalyticsReportBase

    def initialize(opts={})
      set_params opts
      set_option :report_name, "Keyword Summary Report"
      initial_report
      initial_header
    end
    
    def initial_header
      row_cnt = @headers.length
      cols = []
      cols << new_element("Agent's Name", 1, row_cnt)
      cols << new_element("Total Calls", 1, row_cnt)
      add_header(cols,0,-1)
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
      get_result_from_es
      
      # update columns
      cols = []
      @keywords.each do |keyword|
        cols << new_element(keyword, 1, 1)
      end
      add_header(cols,0,-1)
      
      data = []
      @result.each do |rs|
        d =[]
        u = get_user_info(rs[:agent_id])
        d << u[:display_name]
        d << rs[:total]
        @keywords.each do |keyword|
          d << rs[keyword]
        end
        data << d
      end
      return data
    end
    
    def get_result_from_es
      aggs = {
        user: {
          terms: {
            field: 'agent_id',
            size: @opts[:limit],
            order: { "_count": "desc" }
          },
          aggs: {
            word: {
              terms: {
                field: 'keyword_results.result',
                order: { "_count": "desc" },
                size: 100
              }
            }
          }
        }
      }

      v = VoiceLogsIndex::VoiceLog
      v = v.filter(range: {start_time: { gte: @opts[:sdate].strftime("%Y-%m-%d 00:00:00"), lte: @opts[:edate].strftime("%Y-%m-%d 23:59:59"), boost: 2 }})
      
      if @opts[:user_id].present?
        agent_id = @opts[:user_id]
        v = v.filter{ agent_id(:bool) == agent_id }
      end
      
      if @opts[:keyword].present?
        keywords = get_keyword_list
        keywords = "NotFound" if keywords.empty?
        v = v.filter{ keyword_results.result == keywords }
      end
      
      v = v.filter{ keyword_results != nil }.aggregations(aggs)
      
      # parse result
      data = []
      @keywords = []
      result = v.aggs["user"]["buckets"]
      result.each do |rs|
        d = { agent_id: rs["key"], total: rs["doc_count"].to_i, words: 0 }
        rs["word"]["buckets"].each do |word|
          if @opts[:keyword].present?
            next unless word["key"].match(/#{@opts[:keyword]}/)
          end
          @keywords << word["key"]
          d[word["key"]] = word["doc_count"].to_i
        end
        data << d
      end
      
      @keywords = @keywords.uniq
      @result = data
    end
    
    def get_keyword_list
      kwords = Keyword.select(:name).where(["name LIKE ?", "%#{@opts[:keyword]}%"]).not_deleted.all
      return kwords.map { |k| k.name }
    end
    
    # end class
  end
end