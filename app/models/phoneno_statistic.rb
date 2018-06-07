#
# As below description about code of statistic types
# 1xx = count
# 2xx = sum
# 3xx = max
# 4xx = min
# 5xx = avg

class PhonenoStatistic < ActiveRecord::Base

  StatType = Struct.new(:id, :label)
  
  belongs_to  :statistic_calendar,   foreign_key: 'stats_date_id'

  scope :date_between, ->(fr_d,to_d){
    stats = StatisticCalendar.get_id_range(fr_d,to_d)
    where("stats_date_id BETWEEN ? AND ?",stats.first,stats.last)
  }
  
  scope :exclude_special_no, ->{
    numbers = ['1234', '1113', '1133']
    unless numbers.empty?
      where(["number NOT IN (?)",numbers])
    end
  }
  
  def self.code_outbound_count
    # count by dnis (customer), outbound
    statistic_type(:count, :outbound_dnis)  
  end
  
  def self.code_inbound_count
    # count by ani (customer), inbound
    statistic_type(:count, :inbound_ani)
  end
  
  def self.create_joinsql_for_voice_logs(options={})
    # options
    # date-from, date-to
    join_type = "LEFT JOIN"
    co_id = PhonenoStatistic.code_outbound_count.id
    ci_id = PhonenoStatistic.code_inbound_count.id
    sd_id = StatisticCalendar.get_date_id(options[:sdate])
    ed_id = StatisticCalendar.get_date_id(options[:edate])
    
    sql = []
    sql << "SELECT phs.number, dmy.stats_date AS call_date, phs.total AS repeated_count, phs.stats_type AS count_type"
    sql << "FROM phoneno_statistics phs"
    sql << "JOIN statistic_calendars dmy ON phs.stats_date_id = dmy.id AND dmy.stats_hour = -1"
    sql << "WHERE phs.stats_type IN (#{[co_id].join(",")})"
    sql << "AND phs.stats_date_id BETWEEN '#{sd_id}' AND '#{ed_id}'"

    unless options[:type_number].blank?
      types = []
      case options[:type_number]
      when "mob", "mobile"
        types << "MOB"
      when "fixed", "fix", "home", "line"
        types << "FIX"
      when "ext", "extension"
        types << "EXT"
      end
      unless types.empty?
        types = types.map { |p| "'#{p}'"}
        sql << "AND phs.phone_type IN (#{types.join(",")})"
      end
      join_type = "JOIN"
    end

    if options[:count_from].to_i > 0
      sql << "AND phs.total >= #{options[:count_from]}"
      join_type = "JOIN"
    else
      sql << "AND phs.total >= 2"
    end
    
    if options[:count_to].to_i > 0
      sql << "AND phs.total <= #{options[:count_to]}"
      join_type = "JOIN"
    end
    
    join_sql = sql.join(" ")
    join_sql =  "#{join_type} (#{join_sql}) rpc "
    join_sql << "ON ((rpc.number = voice_logs.dnis AND rpc.count_type = #{co_id}) OR (rpc.number = voice_logs.ani AND rpc.count_type = #{ci_id})) "
    join_sql << "AND rpc.call_date = voice_logs.call_date"
    return join_sql
  end
  
  def self.create_exist_sql_for_voice_logs(options={})
    # options
    # date-from, date-to

    co_id = PhonenoStatistic.code_outbound_count.id
    ci_id = PhonenoStatistic.code_inbound_count.id
    
    sql = []
    sql << "SELECT 1 FROM phoneno_statistics"
    sql << "JOIN dmy_calendars ON phoneno_statistics.stats_date_id = dmy_calendars.id"
    sql << "WHERE voice_logs.call_date = dmy_calendars.stats_date"
    sql << "AND ((phoneno_statistics.number = voice_logs.dnis AND phoneno_statistics.stats_type = #{co_id}) OR (phoneno_statistics.number = voice_logs.ani AND phoneno_statistics.stats_type = #{ci_id})) "
    sql << "AND phoneno_statistics.stats_type IN (#{[co_id, ci_id].join(",")})"
    sql << "AND dmy_calendars.stats_date BETWEEN '#{options[:date_from]}' AND '#{options[:date_to]}'"
    
    unless options[:type_number].blank?
      types = []
      case options[:type_number]
      when "mob", "mobile"
        types << "MOB"
      when "fixed", "fix", "home", "line"
        types << "FIX"
      when "ext", "extension"
        types << "EXT"
      end
      unless types.empty?
        types = types.map { |p| "'#{p}'"}
        sql << "AND phoneno_statistics.phone_type IN (#{types.join(",")})"
      end
    end
    
    if options[:count_from].to_i > 0
      sql << "AND phoneno_statistics.total >= #{options[:count_from]}"
    else
      sql << "AND phoneno_statistics.total >= 2"
    end
    
    if options[:count_to].to_i > 0
      sql << "AND phoneno_statistics.total <= #{options[:count_to]}"
    end
    
    sql = sql.join(" ")
    return sql
  end
  
  def self.get_redial_count_per_day(call_date, number, min=2)
    # dialed number
    stat_id = statistic_type(:count, :outbound_dnis).id
    date_id = StatisticCalendar.get_date_id(call_date)
    ps = PhonenoStatistic.select(:total).where({ stats_date_id: date_id, stats_type: stat_id, number: number}).first
    if not ps.nil? and ps.total >= min
      return ps.total
    end
    return nil
  end

  def self.statistic_type(calc_type, calc_for)
    
    code  = []
    label = []
    
    case calc_type.downcase.to_sym
    when :count
      code << '1'
    when :sum
      code << '2'
    when :max
      code << '3'
    when :min
      code << '4'
    when :avg
      code << '5'
    end
    label << calc_type.to_s
    
    case calc_for.downcase.to_sym
    when :all
      code << '01'
    when :inbound_ani
      code << '02'
    when :inbound_dnis
      code << '03'
    when :outbound_ani
      code << '04'
    when :outbound_dnis
      code << '05'
    end
    label << calc_for.to_s
    
    Rails.logger.debug "Get statistics type #{calc_type},#{calc_for} is #{code.join}"

    return StatType.new(code.join, label.join("_"))

  end
  
end
