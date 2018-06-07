class KeywordStatistic < ActiveRecord::Base
  
  StatType      = Struct.new(:id, :label)
  
  belongs_to    :statistic_calendar,   foreign_key: 'stats_date_id'
  belongs_to    :keyword

  def self.statistic_type(calc_type, calc_for)
    
    code  = []
    label = []
    
    case calc_type.downcase.to_sym
    when :count
      code << '1'
    end
    label << calc_type.to_s
    
    case calc_for.downcase.to_sym
    when :word
      code << '00'
    when :call
      code << '01'
    end
    label << calc_for.to_s
    
    return StatType.new(code.join, label.join("_"))

  end
  
end
