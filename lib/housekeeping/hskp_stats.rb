module HousekeepingData
  class HskpStats < Base
    
    def self.cleanup_stats_logs
      hs = HskpStats.new
      hs.cleanup_call_stats
    end
    
    def cleanup_call_stats
      today = Date.today
      del_date = Date.today - Settings.logs.statistics_keep_days.to_i
      target_date_id = StatisticCalendar.get_date_id(del_day) rescue nil
      
      unless target_date_id.nil?
        cond = ["stats_date_id <= ?", target_date_id]
        CallStatistic.delete_all(cond)
        PhonenoStatistic.delete_all(cond)
        cond = ["id <= AND stats_date <= ?",target_date_id, del_day]
        StatisticCalendar.delete_all(cond)
      end
      logger.info("Housekeeping Task for statistics log before #{del_date}")
    end
    
    # end class
  end
end