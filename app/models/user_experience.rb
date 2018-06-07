class UserExperience < ActiveRecord::Base
  
  def length_of_work_in_ym
    
    months = self.length_work.to_i
    ym     = months.divmod(12)
    
    return {
      years:  ym[0],
      months: ym[1]
    }
  
  end
  
  def length_of_work_text
    
    ym = length_of_work_in_ym
    txt = []
    
    if ym[:years] > 0
      txt << "#{ym[:years]} years"
    end
  
    if ym[:months] > 0
      txt << "#{ym[:months]} months"
    end
    
    return txt.join(" ")
  
  end
  
end
