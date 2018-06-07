class MaintenancesController < ApplicationController
  
  before_action :authenticate_user!
  layout 'maintenance'
  
  def index
    
  end
  
  def watcher_status
        
  end
  
  def call_activity
    
    data = {}
    today = Time.now.beginning_of_day
    last30days = today - 1.month
    
    cds = ["i","o"]
    cds.each do |cd|
      sql = "SELECT DATE(start_time) AS call_date, COUNT(DISTINCT extension) AS total_exts, COUNT(DISTINCT agent_id) AS total_agent, SUM(duration) AS total_duration, COUNT(0) AS total_record "
      sql << "FROM voice_logs "
      sql << "WHERE start_time >= '#{last30days.to_formatted_s(:db)}' AND call_direction = '#{cd}' "
      sql << "GROUP BY call_direction, DATE(start_time) "
      sql = "SELECT stats_date,total_agent,total_duration,total_record FROM dmy_calendars d LEFT JOIN (#{sql}) x ON x.call_date = d.stats_date "
      sql << "WHERE stats_date BETWEEN '#{last30days.to_date}' AND '#{today.to_date}' "
      sql << "ORDER BY stats_date "
      
      data[cd.to_sym] = { count: 0, duration: 0, list: [] }
      data[:a] = { count: 0, list: [], exts_count: 0 }
      result = ActiveRecord::Base.connection.select_all(sql)
      result.each_with_index do |rs,i|
        if rs["stats_date"] == today.to_date
          data[cd.to_sym][:count] = rs["total_record"].to_i
          data[cd.to_sym][:duration] = StringFormat.format_sec(rs["total_duration"].to_i)

        end
        data[cd.to_sym][:list] << rs["total_record"].to_i
      end
    end
    
    sql = "SELECT DATE(start_time) AS call_date, COUNT(DISTINCT extension) AS total_exts, COUNT(DISTINCT agent_id) AS total_agent "
    sql << "FROM voice_logs "
    sql << "WHERE start_time >= '#{last30days.to_formatted_s(:db)}' "
    sql << "GROUP BY DATE(start_time) "
    sql = "SELECT stats_date,total_agent,total_exts FROM dmy_calendars d LEFT JOIN (#{sql}) x ON x.call_date = d.stats_date "
    sql << "WHERE stats_date BETWEEN '#{last30days.to_date}' AND '#{today.to_date}' "
    sql << "ORDER BY stats_date "
    result = ActiveRecord::Base.connection.select_all(sql)
    result.each do |rs|
      if rs["stats_date"] == today.to_date
        data[:a][:count] = rs["total_agent"].to_i
        data[:a][:exts_count] = rs["total_exts"]        
      end
      data[:a][:list] << rs["total_agent"].to_i
    end
    
    render json: data
    
  end

  private

end
