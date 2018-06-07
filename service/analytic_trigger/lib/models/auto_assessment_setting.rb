class AutoAssessmentSetting < ActiveRecord::Base

  serialize :setting_string, JSON
  
  def settings
    Hashie.symbolize_keys self.setting_string.first
  end

  def matched_condition?(condition_name, value=nil)
    case condition_name
    when :call_duration
      return matched_call_duration(value)
    when :call_direction
      return matched_call_direction(value)
    when :call_category
      return matched_call_category(value)
    end
    return true
  end
  
  private
  
  def matched_call_duration(value)
    unless settings[:min_duration].nil?
      if value <= settings[:min_duration]
        return false
      end
    end
    return true
  end
  
  def matched_call_direction(value)
    unless settings[:call_direction].nil?
      if not value == settings[:call_direction]
        return false
      end
    end
    return true
  end
  
  def matched_call_category(value)
    unless settings[:call_category].nil?
      if not value.sort == settings[:call_category].sort
        return false
      end
    end
    return true
  end
  
end