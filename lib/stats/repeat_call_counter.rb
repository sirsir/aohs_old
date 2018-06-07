module StatsData
  
  class DailyRepeatedCallCounter < StatsBase
    
    MINIMUM_COUNT = 1
    MINIMUM_TELNO_LENGTH = 3
    
    def self.run(options)
      rpcd = new(options)
      rpcd.run
    end
    
    def run
      (@options[:start_date]..@options[:end_date]).to_a.each do |dt|
        logger.info "updating phone on date #{dt}"
        cleanup_existing(dt)
        update_ani(dt)
        update_dnis(dt)
      end
    end
    
    private
    
    def cleanup_existing(dt)
      # remove existing records
      date_id = get_stats_datekey_id({ stats_date: dt, stats_hour: -1 })
      conds = ["stats_date_id = ? AND stats_type IN (?) AND total >= 0", date_id, getall_types]
      # perform delete existing record
      deleted_count = PhonenoStatistic.where(conds).count(0)
      if deleted_count > 0
        PhonenoStatistic.where(conds).delete_all
      end
    end
    
    def update_ani(dt)
      # number of call group by ani and call direction
      update_number(:ani,dt)
    end
  
    def update_dnis(dt)
      # number of call by ani and call direction
      update_number(:dnis,dt)
    end
    
    def update_number(mode,dt)
      selects, groups = group_and_select(mode)
      result = get_result(dt, groups, selects)    
      stats_type = stats_type_count(mode)
      
      dc = get_stats_datekey(dt)
      date_id = get_stats_datekey_id(dc)

      result.each do |rs|
        next if rs.telno.length <= MINIMUM_TELNO_LENGTH
        next unless require_save?(rs.total_count)
        update_record(date_id,rs.telno,stats_type[rs.call_direction.to_sym],rs.total_count)
      end
      
      result = nil
    end
    
    def update_record(dt_id, number, stype, val)
      
      rec = {
        stats_date_id: dt_id,
        number: number,
        stats_type: stype
      }
      
      nrec = PhonenoStatistic.where(rec).first
      if nrec.nil?
        phone = PhoneNumber.new(number)
        rec[:formatted_number] = phone.real_number
        rec[:phone_type] = phone.phone_type.upcase
        nrec = PhonenoStatistic.new(rec)
      end
      
      nrec.total = val.to_i
      nrec.save
    
    end

    def require_save?(count)
      return count.to_i >= MINIMUM_COUNT
    end

    def group_and_select(mode)
      
      select = []
      group = [
        "call_date"
      ]
      
      case mode
      when :ani
        select << "ani AS telno"
        group << "ani"
      when :dnis
        select << "dnis AS telno"
        group << "dnis"
      end
      
      select.concat(["call_direction", "COUNT(id) AS total_count"])
      group.concat(["call_direction"])

      return select, group
      
    end

    def stats_type_count(mode)
      
      case mode
      when :ani
        return {
          i: get_stats_type(:count, :inbound_ani),
          o: get_stats_type(:count, :outbound_ani)
        }
      when :dnis
        return {
          i: get_stats_type(:count,:inbound_dnis),
          o: get_stats_type(:count,:outbound_dnis)
        }
      else
        return {}
      end
      
    end
    
    def get_result(dt, groups, selects, wheres=nil)
      d1, d2 = get_date_fromto(dt)
      return VoiceLog.start_time_bet(d1, d2).group(jn_group(groups)).select(jn_select(selects)).all
    end

    def getall_types
      types = [
        get_stats_type(:count, :inbound_ani),
        #get_stats_type(:count, :inbound_dnis),
        #get_stats_type(:count, :outbound_ani)
        get_stats_type(:count, :outbound_dnis)
      ]
      return types
    end
    
    def get_stats_type(t,f)
      return PhonenoStatistic.statistic_type(t,f).id
    end
    
    # end class
  end
  
  # end module
end