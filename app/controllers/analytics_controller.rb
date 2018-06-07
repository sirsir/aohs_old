require 'net/http'
require 'json'

class AnalyticsController < ApplicationController

  before_action :authenticate_user!
  
  def index
    calendar_data
  end
  
  def word_cloud
    respond_to do |format|
      format.html do
        # nothing
      end
      format.json do
        get_list_wordcloud
        render json: @wordclouds
      end
    end
  end
  
  
  
  
  
  
  
  
  def classification

    respond_to do |format|
      format.html do
        # nothing
      end
      format.json do
        ana = AnalyticReport::ClassificationReport.new(report_params)
        render json: ana.get_result
      end
    end
    
  end
  
  #def reason
  #  
  #  data = {
  #    name: "all",
  #    children: [
  #      { name: "A", size: 10 },
  #      { name: "B", size: 10, children: [
  #        { name: "AA", size: 6 },
  #        { name: "AB", size: 4 }
  #      ]},
  #      { name: "C", size: 10, children: [
  #        { name: "CA", size: 6 },
  #        { name: "CB", size: 2 },
  #        { name: "CC", size: 3 }
  #      ]},
  #    ]
  #  }
  #  
  #  respond_to do |format|
  #    format.html do
  #      # nothing
  #    end
  #    format.json do
  #      render json: data
  #    end
  #  end
  #  
  #end

  def dasb_call_class
    
    sdate = Date.parse(params[:fr_d])
    edate = Date.parse(params[:to_d])
    vtype = params[:type].to_sym
    
    if params[:category_id].present? and params[:category_id].to_i > 0
      sql_x = "SELECT 1 FROM call_classifications cx WHERE v.id = cx.voice_log_id AND cx.call_category_id = #{params[:category_id]}"
    else
      sql_x = nil
    end
  
    # count by categoty and type
    sql_a = []
    sql_a << "SELECT c.call_category_id, COUNT(DISTINCT v.agent_id) AS agent_count, COUNT(0) AS total_count"
    sql_a << "FROM voice_logs v JOIN call_classifications c"
    sql_a << "ON v.id = c.voice_log_id"
    sql_a << "WHERE v.start_time BETWEEN '#{sdate} 00:00:00' AND '#{edate} 23:59:59'"
    sql_a << "AND v.flag <> 'd' AND c.flag <> 'd'"
    unless sql_x.nil?
      sql_a << "AND EXISTS (#{sql_x})"
    end
    sql_a << "GROUP BY c.call_category_id"
    sql_a = sql_a.join(" ")
    
    sql_b = []
    sql_b << "SELECT c.id, c.title, c.category_type, sq1.total_count, sq1.agent_count"
    sql_b << "FROM (#{sql_a}) sq1 JOIN call_categories c ON sq1.call_category_id = c.id"
    sql_b << "WHERE c.flag <> 'd'"
    sql_b << "ORDER BY c.category_type, sq1.total_count DESC"
    sql = sql_b.join(" ")
    
    # count by period
    sdate_dt = sdate
    edate_dt = edate
    
    case vtype
    when :monthly
      #sdate_dt = sdate_dt - 30.days
    when :weekly
      sdate_dt = sdate_dt - 30.days
    else
      sdate_dt = sdate_dt - 30.days
    end
    
    data = []
    cate_types = []
    tops = []
    max_top = 5
    total_count = 0
    
    result = ActiveRecord::Base.connection.select_all(sql)
    result.each do |rs|
      sql_c = []
      sql_c << "SELECT DATE(v.start_time) AS call_date, c.call_category_id, COUNT(0) AS total_count"
      sql_c << "FROM voice_logs v JOIN call_classifications c"
      sql_c << "ON v.id = c.voice_log_id"
      sql_c << "WHERE c.call_category_id = #{rs["id"]}"
      sql_c << "AND v.start_time BETWEEN '#{sdate_dt} 00:00:00' AND '#{edate_dt} 23:59:59'"
      sql_c << "AND v.flag <> 'd' AND c.flag <> 'd'"
      unless sql_x.nil?
        sql_c << "AND EXISTS (#{sql_x})"
      end
      sql_c << "GROUP BY DATE(v.start_time), c.call_category_id "
      sql_c = sql_c.join(" ")
      
      sql_d = []
      sql_d << "SELECT d.stats_date, x.call_category_id, x.total_count"
      sql_d << "FROM dmy_calendars d LEFT JOIN (#{sql_c}) x"
      sql_d << "ON x.call_date = d.stats_date"
      sql_d << "WHERE stats_date BETWEEN '#{sdate_dt}' AND '#{edate_dt}' "
      sql_d << "ORDER BY d.stats_date"
      sql_d = sql_d.join(" ")
      
      result2 = ActiveRecord::Base.connection.select_all(sql_d)
      list = []
      result2.each do |r2|
        list << r2["total_count"].to_i
      end
      data << { id: rs["id"], title: rs["title"], category_type: rs["category_type"].to_s, count: rs["total_count"], agent_count: rs["agent_count"].to_i, avg_agent: rs["total_count"].to_i/rs["agent_count"].to_i,  list: list }
      cate_types << rs["category_type"] unless rs["category_type"].blank?
      total_count += rs["total_count"].to_i
      tops << { id: rs["id"], title: rs["title"], category_type: rs["category_type"].to_s, count: rs["total_count"], percentage: 0 }
    end
    
    tops = tops.sort { |x,y| x[:count] <=> y[:count] }
    tops = tops.reverse.take(5)
    tops.each do |top|
      top[:percentage] = (top[:count].to_f/total_count.to_f * 100.0).round(2)
    end
    
    cate_types = cate_types.uniq
    cate_types << ""
    
    render json: { types: cate_types, result: data, tops: tops }
    
  end

  private
  
  def report_params
    
    conds = {}
    
    if params.has_key?(:period_type)
      conds[:period_type] = params[:period_type].downcase.to_sym
    end
    
    if params.has_key?(:date_range)
      d = date_range(params[:date_range])
      conds[:sdate] = d[0]
      conds[:edate] = d[1]
    end
    
    if params.has_key?(:group_name) and not params[:group_name].empty?
    
    end

    if params.has_key?(:user_name) and not params[:user_name].empty?
      usr = User.select(:id).name_like(params[:user_name]).all
      unless usr.empty?
        conds[:users] = usr.map { |u| u.id }
      else
        conds[:users] = [0]
      end
    end
    
    if params.has_key?(:view_as) and not params[:view_as].empty?
      conds[:view_as] = params[:view_as].downcase.to_sym
    end
    
    return conds
    
  end
  
  private

  def get_list_wordcloud
    @wordclouds = {}

    pams = word_cloud_params
    aggs = {
      word: {
        terms: {
          field: 'words.word',
          order: { "_count": "desc" },
          size: pams[:top]
        }
      }
    }

    v = VoiceLogsIndex::VoiceLog #.filter{ site_id == 9 }
    unless pams[:speaker_type].nil?
      v.filter{ words.speaker_type == pams[:speaker_type] }
    end
    unless pams[:date_range].nil?
      d = pams[:date_range].map { |d| d.strftime("%Y-%m-%d") }
      v = v.filter(range: {start_time: { gte: d.first + " 00:00:00", lte: d.last + " 23:59:59" }})
    end
    unless pams[:call_category].nil?
      pams[:call_category].each do |cate|
        v = v.filter{ call_categories == cate }
      end
    end
    v = v.filter{ words != nil }.aggregations(aggs)
        
    # total record
    total_record = v.search_type(:count).total
    
    # result
    result = v.aggs['word']['buckets']
    data = []
    topdata = []
    result = (result.sort { |a,b| a["doc_count"] <=> b["doc_count"] }).reverse
    result.each do |d|
      topdata << { word: d["key"], count: d["doc_count"], percentage: (d["doc_count"].to_f/total_record.to_f*100.0).round(2)  }
      data << [d["key"],d["doc_count"].to_f/total_record.to_f*100]
    end
    topdata = topdata.take(10)
    
    @wordclouds = { wordcloud: data, top: topdata }
  end
  
  def word_cloud_params
    pams = {}
    
    # top view
    if params[:top_view].present?
      pams[:top] = params[:top_view].to_i
    else
      pams[:top] = 10
    end
    
    # speaker_type
    if params[:speaker_type].present? and not params[:speaker_type].empty?
      pams[:speaker_type] = params[:speaker_type]
    end
    
    # date range
    if params[:date_range].present?
      pams[:date_range] = date_range(params[:date_range])
    end
    
    # call category
    if params[:call_categories].present?
      pams[:call_category] = params[:call_categories].map { |c| c.to_i }
    end
    
    return pams
  end

  def date_range(date_string)
    sdate = Date.today, edate = Date.today
    result = date_string.gsub(" ","").match(/(\d{4}-\d{2}-\d{2})-(\d{4}-\d{2}-\d{2})/)
    unless result.nil?
      sdate = Date.parse(result[1])
      edate = Date.parse(result[2])
    end
    return [sdate, edate]
  end
  
  def calendar_data

    target_date = Date.today
    select_type = :month
    
    if params[:year].present? and params[:week].present?
      target_date = Date.commercial(params[:year].to_i, params[:week].to_i)
      select_type = :week
    else
      params[:year] = target_date.year unless params[:year].present?
      params[:month] = target_date.month unless params[:month].present?
      if params[:day].present?
        select_type = :day
        target_date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
      else
        select_type = :month
        target_date = Date.new(params[:year].to_i, params[:month].to_i)
      end
    end
    
    @calendar_selected_date = target_date
    @calendar_prev_date = target_date.prev_month
    @calendar_next_date = target_date.next_month
    
    @calendar_sdate = @calendar_selected_date
    @calendar_edate = @calendar_selected_date
    @calendar_label = @calendar_selected_date.to_formatted_s(:web)
    @select_type = :daily
    case select_type
    when :month
      @calendar_sdate = @calendar_selected_date.beginning_of_month
      @calendar_edate = @calendar_selected_date.end_of_month
      @calendar_label = @calendar_selected_date.strftime("%b, %Y")
      @select_type = :monthly
    when :week
      @calendar_sdate = @calendar_selected_date.beginning_of_week
      @calendar_edate = @calendar_selected_date.end_of_week
      @calendar_label = @calendar_sdate.strftime("%d, %b") + " - " + @calendar_edate.strftime("%d, %b")
      @select_type = :weekly
    end
    
    @calendar_data = []
    
    sd = @calendar_selected_date.beginning_of_month.beginning_of_week
    ed = @calendar_selected_date.end_of_month.end_of_week
    
    while sd <= ed
      items = [{
        title: sd.cweek,
        year: sd.year,
        type: 'week'
      }]
      while sd.cweek == (sd+1).cweek
        items << {
          title: sd.mday,
          year: sd.year,
          month: sd.month,
          week: sd.cweek,
          day: sd.mday,
          type: 'day'
        }
        sd += 1
      end
      items << {
        title: sd.mday,
        year: sd.year,
        month: sd.month,
        week: sd.cweek,
        day: sd.mday,
        type: 'day'
      }
      sd += 1
      @calendar_data << items
      break if sd > Date.today
    end
    
    @calendar_months_pick = []
    dm = Date.today.beginning_of_month
    while dm >= Date.today - 1.year
      @calendar_months_pick << dm
      dm -= 1.month
    end
    
  end
  
  # end class
end
