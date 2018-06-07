
# description about code of statistic types
#
# 1xx = count
# 2xx = sum
# 3xx = max
# 4xx = min
# 5xx = avg
#

class CallStatistic < ActiveRecord::Base
  
  StatType      = Struct.new(:id, :label)
  StatTypeRange = Struct.new(:id, :label, :lower_bound, :upper_bound, :display_name)
  
  belongs_to    :statistic_calendar,   foreign_key: 'stats_date_id'
  
  scope :daily, ->{
    group('statistic_calendar.stats_date')
  }
  
  scope :hourly, ->{
    group('statistic_calendar.stats_date, statistic_calendar.stats_hour')  
  }
  
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
    when :inbound
      code << '02'
    when :outbound
      code << '03'
    when :inbound_duration
      code << '04'
    when :outbound_duration
      code << '05'
    when :inbound_range
      code << '06'
    when :outbound_range
      code << '07'
    end
    label << calc_for.to_s

    # STDOUT.puts "Get statistics type #{calc_type},#{calc_for} is #{code.join}"
    
    return StatType.new(code.join, label.join("_"))

  end
  
  def self.statistic_type_ranges(calc_type, calc_for, range_name)
    
    ranges = []
    
    case range_name
    when :duration_range
      minv = 0
      Settings.statistics.duration_ranges.each_with_index do |r,i|
        range = statistic_type(calc_type, calc_for)
        display_name = "#{StringFormat.format_sec(minv)} - #{StringFormat.format_sec(r)}"
        ranges << StatTypeRange.new((range.id << i.to_s), (range.label << "_range#{i}"),minv,r, display_name)
        minv = r + 1
      end
      range = statistic_type(calc_type, calc_for)
      i = ranges.length
      display_name = "> #{StringFormat.format_sec(minv-1)}"
      ranges << StatTypeRange.new((range.id << i.to_s), (range.label << "_range#{i}"),minv,nil,display_name)
    end
    
    return ranges
    
  end
  
end
