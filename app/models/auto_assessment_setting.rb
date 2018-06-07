class AutoAssessmentSetting < ActiveRecord::Base
  
  # Settings Parameters for Auto Assessment
  # voice_logs.call_diretion
  # voice_logs.duration (minimum)
  # call_classifications.call_category_id (only)
  #
  # Settings String
  # [ {rule 1}, { rule 2}, {rule N} ]
  #
  
  belongs_to  :evaluation_plan
  
  serialize :setting_string, JSON
  
  default_value_for   :flag,  ""
  
  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }
  
  scope :only_disable, ->{
    where(flag: "S")
  }
  
  scope :only_enabled, ->{
    where.not(flag: [DB_DELETED_FLAG, "S"])  
  }
  
  scope :by_plan_id, ->(id){
    where(evaluation_plan_id: id)  
  }
  
  def self.update_settings(evaluation_plan_id, asst_params)
    # mark delete
    lst_setting = by_plan_id(evaluation_plan_id).not_deleted.first
    unless lst_setting.nil?
      lst_setting.do_delete
      lst_setting.save
    end
    # save new
    lst_setting = AutoAssessmentSetting.new
    lst_setting.evaluation_plan_id = evaluation_plan_id
    lst_setting.setting_string = asst_params
    lst_setting.do_init
    lst_setting.save
    return true
  end
  
  def settings
    Hashie.symbolize_keys self.setting_string.first
  end
  
  def status_name
    if enabled?
      return "Enabled"
    elsif disabled?
      return "Disabled"
    end
    return ""
  end
  
  def deleted?
    self.flag == DB_DELETED_FLAG
  end
  
  def enabled?
    self.flag == ""  
  end
  
  def disabled?
    self.flag == "S"  
  end
  
  def do_init
    self.flag = ""
    asst = self.settings
    if not asst.nil? and asst[:enable] == false
      self.flag = "S"
    end
  end

  def do_delete
    self.flag = DB_DELETED_FLAG
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
  
  # end class
end
