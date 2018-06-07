module StatsData
  class CallAgentStats < StatsBase
    
    def self.run(options={})
      cas = new(options)
      cas.run
    end
    
    def run
      dates = find_target_date
      dates.each do |ps_date|
        logger.info "updating call date on date #{ps_date}"
        cleanup_existing_log(ps_date)
        call_direction_statistics(:inbound, ps_date)
        call_direction_statistics(:outbound, ps_date)
      end
    end

    private
    
    def find_target_date
      return (@options[:start_date]..@options[:end_date]).to_a
    end

    def cleanup_existing_log(ps_date)
      codes = []
      [:inbound, :outbound].each do |dir|
        codes << CallStatistic.statistic_type(:count,dir)
        codes << CallStatistic.statistic_type(:sum,dir)
        codes << CallStatistic.statistic_type(:max,dir)
      end
      dc = get_stats_date(ps_date)
      CallStatistic.delete_all({ stats_date_id: get_stats_date_id(dc), stats_type: codes})
    end

    def call_direction_statistics(dir, ps_date)
      ps_date = ps_date.strftime("%Y-%m-%d")
      fr_d = Time.parse("#{ps_date} 00:00:00")
      to_d = Time.parse("#{ps_date} 23:59:59")
      case dir
      when :inbound
        cdir = VL_INBOUND
      when :outbound
        cdir = VL_OUTBOUND
      else
        return false
      end
      select  = [
        "agent_id",
        "DATE(start_time) AS call_date",
        "COUNT(0) AS total_calls",
        "SUM(duration) AS total_duration",
        "MAX(duration) AS max_duration"
      ].concat(get_select_duration_range(dir))
      
      select  = select.join(",")
      
      group   = [
        "agent_id"
      ].join(",")
      
      conds   = {
        start_time_bet: [fr_d, to_d],
        call_direction_eq: cdir
      }
      
      result = get_result(select, conds, group)
      unless result.empty?
        result.each do |rs|
          update_by_call_direction(dir, rs)
        end
      end
    end
    
    def get_select_duration_range(dir)
      selects = []
      ranges = CallStatistic.statistic_type_ranges(:count, dir, :duration_range)
      unless ranges.empty?
        ranges.each do |r|
          if not r.lower_bound.nil? and not r.upper_bound.nil?
            selects << "SUM(IF(duration BETWEEN #{r.lower_bound} AND #{r.upper_bound},1,0)) AS #{r.label}"
          else
            selects << "SUM(IF(duration >= #{r.lower_bound},1,0)) AS #{r.label}"
          end
        end
      end
      return selects
    end

    def get_result(select, conds, group)
      result  = VoiceLog.search(conds).result
      result  = result.select(select).group(group).order(false).all
      return result
    end

    def update_by_call_direction(dir,rs)
      
      group_id = 0
      u = User.where(id: rs.agent_id).first
      unless u.nil?
        group_id = u.group_id 
      end
  
      dc = get_stats_date(rs.call_date)
      ds = {
        stats_date_id: get_stats_date_id(dc),
        agent_id: rs.agent_id.to_i,
        group_id: group_id
      }
      
      ds[:stats_type] = CallStatistic.statistic_type(:count,dir).id
      cs = CallStatistic.where(ds).first
      if cs.nil?
        cs = CallStatistic.new(ds)
      end
      cs.total = rs.total_calls.to_i
      cs.save!
  
      ds[:stats_type] = CallStatistic.statistic_type(:sum,dir.to_s << "_duration").id
      cs = CallStatistic.where(ds).first
      if cs.nil?
        cs = CallStatistic.new(ds)
      end
      cs.total = rs.total_duration.to_i
      cs.save!
  
      ds[:stats_type] = CallStatistic.statistic_type(:max,dir.to_s << "_duration").id
      cs = CallStatistic.where(ds).first
      if cs.nil?
        cs = CallStatistic.new(ds)
      end
      cs.total = rs.max_duration.to_i
      cs.save!
      
      ranges = CallStatistic.statistic_type_ranges(:count, dir, :duration_range)
      ranges.each do |r|
        ds[:stats_type] = r.id
        cs = CallStatistic.where(ds).first
        if cs.nil?
          cs = CallStatistic.new(ds)
        end
        cs.total = rs[r.label.to_sym].to_i
        cs.save!
      end  
    end
    
    def get_stats_date(d)
      return StatisticCalendar.stats_key(:daily, d)
    end
    
    def get_stats_date_id(d)
      cond = {
        stats_date: d[:stats_date],
        stats_hour: d[:stats_hour]
      }
      return StatisticCalendar.where(cond).first.id
    end
    
    # end class 
  end
end