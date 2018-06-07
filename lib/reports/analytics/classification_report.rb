module AnalyticReport
  class ClassificationReport < AnalyticsReportBase
    
    def initialize(opts={})
      @opts = options(opts)
      initial_header
    end
    
    def get_result
      
      build_sql
      
      return {
        header: @headers,
        data: get_data,
        summary: @categories
      }
    
    end
    
    private
    
    def initial_header
      
      init_report
      date_range_init
      category_list
      header = dmy_header

      cols = []
      cols << "Category"
      
      header[:days].each do |d|
        cols << new_element(d[:full_label],1,1)
      end
      
      add_header(cols, 0, 0)
      
    end
    
    def get_data
    
      result = select_sql(@sql)
      cl_result = map_date_array(select_sql(@sql_call))
      
      sum = {}
      ret = []
      
      result.each do |r|
        rs = []
        k = r["call_category_id"].to_s
        next if @categories[k].nil?
        @categories[k][:total_count] += r["total_record"].to_i
        rs << @categories[k][:name]
        @dsel_range.each_with_index do |d,i|
          if @view_mode == :percentage
            rs << StringFormat.num_format((r["c#{i}"].to_i / cl_result[i].to_f) * 100)
          else
            rs << r["c#{i}"].to_i
          end
        end
        ret << rs
      end
      
      cateories = []
      @categories.each do |k,v|
        next if v[:total_count] <= 0
        tt = v[:total_count]
        if @view_mode == :percentage
          tt = StringFormat.num_format((v[:total_count].to_f/@total_call.to_f)*100.0)
        end
        cateories << {
          name: v[:name],
          value: tt
        }
      end
      
      @categories = cateories.sort { |a,b| a[:value] <=> b[:value] }
      @categories = @categories.reverse
      
      return ret
    
    end
  
    def build_sql
      
      v = VoiceLog.table_name
      c = CallClassification.table_name
      
      # select summary of category by date
      
      select = [
        "DATE(v.start_time) AS call_date",
        "c.call_category_id",
        "COUNT(0) AS total_record"
      ]
      
      conds = []
      conds << "v.start_time BETWEEN '#{@sdate} 00:00:00' AND '#{@edate} 23:59:59'"
      
      group = [
        "c.call_category_id"
      ]
      
      sql = []  
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM #{v} v JOIN #{c} c ON v.id = c.voice_log_id"
      sql << "WHERE #{jn_where(conds)}"
      sql << "GROUP BY #{jn_groups(group)}"
      
      sqla = jn_sql(sql)
      
      select = [
        "r.call_category_id",
        "SUM(r.total_record) AS total_record"
      ]
      
      @dsel_range.each_with_index do |d,i|
        case @period_type
        when :daily
          select << "SUM(IF(d.stats_date='#{d[:s_date_str]}',r.total_record,0)) AS c#{i}"  
        when :weekly
          select << "SUM(IF(d.stats_yearweek='#{d[:s_yearweek]}',r.total_record,0)) AS c#{i}"
        when :monthly
          select << "SUM(IF(d.stats_yearmonth='#{d[:s_yearmonth]}',r.total_record,0)) AS c#{i}"
        end
      end
      
      group = [
        "r.call_category_id"
      ]

      sql = []
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM (#{sqla}) r JOIN dmy_calendars d ON r.call_date = d.stats_date"
      sql << "GROUP BY #{jn_groups(group)}"
      sql << "ORDER BY SUM(r.total_record) DESC"
      
      @sql = jn_sql(sql)

      # sql for call-count
      
      select = [
        "DATE(v.start_time) AS call_date",
        "COUNT(0) AS total_record"
      ]
      
      group = [
        "DATE(v.start_time)"
      ]
      
      conds = []
      conds << "v.start_time BETWEEN '#{@sdate}' AND '#{@edate}'"
      
      sql = []
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM #{v} v "
      sql << "WHERE #{jn_where(conds)}"
      sql << "GROUP BY #{jn_groups(group)}"
    
      select = []
      group = []
      
      case @period_type
      when :daily
        select << "d.stats_date AS dcol"
        group << "d.stats_date" 
      when :weekly
        select << "d.stats_yearweek AS dcol"
        group << "d.stats_yearweek"
      when :monthly
        select << "d.stats_yearmonth AS dcol"
        group << "d.stats_yearmonth"
      end
      select << "MIN(d.stats_date) AS key_date"
      order = group
      
      select << "SUM(r.total_record) AS total_record"

      sql_a = []
      sql_a << "SELECT #{jn_select(select)}"
      sql_a << "FROM (#{jn_sql(sql)}) r JOIN dmy_calendars d ON r.call_date = d.stats_date"
      sql_a << "GROUP BY #{jn_groups(group)}"
      sql_a << "ORDER BY #{jn_orders(order)}"
      
      @sql_call = jn_sql(sql_a)
      
    end
    
    def map_date_array(result)
      
      ret = []
      @total_call = 0
      
      @dsel_range.each_with_index do |d,i|
        isset = false
        result.each do |rs|
          if d[:s_date].to_formatted_s(:db) == rs["key_date"].to_formatted_s(:db) 
            ret << rs["total_record"].to_i
            @total_call += rs["total_record"].to_i
            isset = true
            break
          end
        end
        ret << 0 unless isset
      end
      
      return ret
    
    end
    
    def options(opts)
      @sdate = opts[:sdate].to_formatted_s(:db)
      @edate = opts[:edate].to_formatted_s(:db)
      @period_type = opts[:period_type]
      @view_mode = opts[:view_as]
      return opts
    end
    
    def category_list
      @categories = {}
      categories = CallCategory.not_deleted.all
      categories.each do |c|
        k = c.id.to_s
        @categories[k] = { id: c.id, name: c.title, total_count: 0 }
      end
    end
    
  end
end
