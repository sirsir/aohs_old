class DatetimeParser
  
  def self.to_date(str, default=nil)
    
    begin
      result = Chronic.parse(str)
      unless result.nil?
        result = result.beginning_of_day.to_date
      else
        result = default
      end
    rescue => e
      result = default
    end
    
    return result
  
  end
  
  def self.to_datetime(str)
    
  end
  
end