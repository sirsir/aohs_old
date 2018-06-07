require 'logger'

module StatsData
  class StatsBase
    
    def initialize(options={})
      default_options(options)
    end
    
    def default_options(options)
      @options = {}
      # check parameters
      @options[:ndays] = options[:ndays] if options[:ndays].present?
      @options[:date] = default_date(options[:date], options[:default_date])
      @options[:date_s] = @options[:date].strftime("%Y-%m-%d")
      
      logger.info "process started."
      logger.info "options: #{@options.to_json}"
    end
    
    def default_date(date,df=:yesterday)
      case date.to_s
      when 'yesterday'
        target_date = Date.today - 1
      when 'today'
        target_date = Date.today
      else
        target_date = Date.parse(date) rescue Date.today
      end
      
      if @options[:ndays].present?
        ndays = @options[:ndays].to_i
        if ndays >= 0
          sdt = Time.parse((target_date).strftime("%Y-%m-%d")).beginning_of_day
          edt = Time.parse((target_date + ndays).strftime("%Y-%m-%d")).end_of_day
        else
          sdt = Time.parse((target_date + ndays).strftime("%Y-%m-%d")).beginning_of_day
          edt = Time.parse((target_date).strftime("%Y-%m-%d")).end_of_day
        end
      else
        sdt = Time.parse(target_date.strftime("%Y-%m-%d")).beginning_of_day
        edt = Time.parse(target_date.strftime("%Y-%m-%d")).end_of_day      
      end
      edt = Time.now if edt >= Time.now
      
      @options[:start_date] = sdt.to_date
      @options[:end_date] = edt.to_date
      @options[:start_datetime] = sdt
      @options[:end_datetime] = edt
      
      return target_date
    end

    def get_date_fromto(d)
      fr_d = Time.parse("#{d} 00:00:00")
      to_d = Time.parse("#{d} 23:59:59")
      to_d = Time.now - Settings.statistics.delay_time_sec if to_d >= Time.now
      return [fr_d, to_d]
    end

    def get_stats_datekey(d)  
      return StatisticCalendar.stats_key(:daily, d)
    end

    def get_stats_datekey_id(d)
      cond = {
        stats_date: d[:stats_date],
        stats_hour: d[:stats_hour]
      }
      return StatisticCalendar.where(cond).first.id  
    end
    
    def job_info(name, status)
      ScheduleInfo.info(name,status)
    end
    
    def jn_select(items)
      return items.join(",")  
    end
    
    def jn_group(items)
      return items.join(",")
    end

    def jn_where(items)
      return items.join(" AND ")
    end

    def jn_sql(items)
      return items.join(" ")
    end
    
    def db_datetime(d)
      if d.is_a?(Date)
        return d.strftime("%Y-%m-%d")
      elsif d.is_a?(Time)
        return d.strftime("%Y-%m-%d %H:%M:%S")
      else
        return d
      end
    end
      
    def select_all(sql)
      logger.debug "sql: #{sql}"
      return ActiveRecord::Base.connection.select_all(sql)  
    end
    
    def execute_sql(sql)
      logger.debug "sql: #{sql}"
      return ActiveRecord::Base.connection.execute(sql) 
    end
    
    private
    
    def logger
      unless defined? @logger
        @logger = Logger.new(File.join(Rails.root,'log','stats_data.log'), 'daily')
        @logger.formatter = proc do |severity, datetime, progname, msg|
          date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
          "[#{date_format}] #{severity} (#{self.class.name.split("::").last}): #{msg}\n"
        end
      end
      return @logger
    end
    
    # end class
  end
  # end module
end
