module StatsData
  class CalendarMaker < StatsBase
    
    NEXT_DAYS_CREATE = 15 
    KEEP_YEARS       = 5
    
    def self.run
      scm = new
      scm.update
    end
    
    def update
      start_date, end_date = calendar_period
      begin
        xdate = start_date
        while xdate <= end_date  
          ds = StatisticCalendar.stats_key(:ymd_key, xdate)
          update_daily(ds)
          update_hourly(ds)
          xdate += 1
        end
        deleted_unused
        logger.info "Updated calendar from #{start_date} to #{end_date}"
      rescue => e
        logger.error e.message
      end
    end
    
    private
    
    def calendar_period
      end_date = Date.today + NEXT_DAYS_CREATE
      start_date = (KEEP_YEARS * 12).months.ago.to_date
      return start_date, end_date
    end
    
    def update_daily(ds)
      ds[:stats_hour] = -1
      cond = {
        stats_date: ds[:stats_date],
        stats_hour: ds[:stats_hour]
      }
      update_ifnot_exist(cond,ds)
    end
  
    def update_hourly(ds)
      24.times do |t|
        ds[:stats_hour] = sprintf "%02d", t
        cond = {
          stats_date: ds[:stats_date],
          stats_hour: ds[:stats_hour]
        }
        update_ifnot_exist(cond,ds)
      end
    end
   
    def update_ifnot_exist(cond,ds)
      if StatisticCalendar.where(cond).count(0) <= 0
        sc = StatisticCalendar.new(ds)
        sc.attributes = {
          id: stats_id(ds)
        }
        sc.save!
      end
    end

    def deleted_unused
      start_date, end_date = calendar_period
      StatisticCalendar.delete_all(["stats_date <= ?",start_date])
    end
  
    def stats_id(ds)
      return [
        ds[:stats_yearmonth][-4,4],
        ds[:stats_day],
        hr_x(ds[:stats_hour])
      ].join("")
    end
    
    def hr_x(hr)
      return ((hr == -1 or hr == '-1') ? '99' : hr)
    end
  
    # end class
  end
end