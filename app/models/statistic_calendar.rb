class StatisticCalendar < ActiveRecord::Base
  
  # No value
  NOVAL = -1
  
  has_many    :call_statistics, primary_key: 'stats_date_id'
  has_many    :keyword_statistics, primary_key: 'stats_date_id'
  
  scope :hourly, ->{
    where("statistic_calendars.stats_hour >= 0")  
  }
  
  scope :daily, ->{
    where("statistic_calendars.stats_hour < 0")  
  }
  
  scope :date_between, ->(d_fr, d_to){
    where(["statistic_calendars.stats_date BETWEEN ? AND ?",d_fr, d_to])
  }
  
  scope :past_days, ->(n){
    where(["statistic_calendars.stats_date >= ?",n.days.ago.to_date])
  }
  
  scope :order_by_default, ->{
    order(:stats_yearmonth,:stats_date)
  }
  
  def self.stats_key(t, d)
    
    xd, xy, xym, xw, xc = date_split(d)
    
    case t
    when :ymd_key
      return {
        stats_date: xd,
        stats_year: xy,
        stats_yearmonth: xym,
        stats_yearweek: "#{xy}#{xw}",
        stats_week: xw,
        stats_day: xc,
      }
    when :daily
      return {
        stats_date: xd,
        stats_year: xy,
        stats_yearmonth: xym,
        stats_yearweek: "#{xy}#{xw}",
        stats_week: xw,
        stats_day: xd,
        stats_hour: NOVAL
      }
    when :hourly
      return nil
    end
    
    return nil
  
  end
  
  def self.get_id_range(min_d, max_d, type=:daily)
    
    selects = "MIN(id) AS min_id, MAX(id) AS max_id"
    conds = ["stats_date BETWEEN ? AND ? AND stats_hour < 0", min_d, max_d]
    
    rs = select(selects).where(conds).order(false).first
    
    return [
      rs.min_id,
      rs.max_id
    ]
    
  end
  
  def self.get_date_id(d)
    # get id of date
    conds = ["stats_date = ?",d]
    rs = select("id").where(conds).daily.order(false).first
    return rs.id
  end
  
  def self.get_date(d)  
    rs = select('stats_date').where(["id = ?",d]).daily.first
    return (rs.nil? ? nil : rs.stats_date)
  end

  private
  
  def self.date_split(d)
    
    # date, year, yearmonth, nweek, day
    # date = 0000-00-00
    # year = 0000
    # yearmonth = 000000
    # week = 1-53
    # day = 0-28|29|30|31
    
    return [
      d.strftime("%Y-%m-%d"),
      d.strftime("%Y"),
      d.strftime("%Y%m"),
      sprintf("%02d",d.cweek),
      d.strftime("%d")
    ]
  
  end
  
end
