class Privilege < ActiveRecord::Base
  
  FLAG_HIDDEN = 'H'
  CATEGORIES  = ["General", "Analytics and Reports", "Evaluation Settings", "Maintenance and Settings", "Logging"]
  
  has_paper_trail
  
  has_many     :permissions
  
  scope :privilege_name, ->(mod_n, act_n, lnk_n=nil) {
    unless lnk_n.nil?
      where(module_name: mod_n, event_name: act_n, link_name: lnk_n)
    else
      where(module_name: mod_n, event_name: act_n, link_name: "")
    end
  }
  
  scope :order_specific_vals, ->{
    vals = CATEGORIES.map { |v| "'#{v}'" }
    order("FIELD(category,#{vals.join(",")}), order_no, module_name")
  }
  
  scope :disabled_function, ->{
    where(flag: FLAG_HIDDEN)
  }
  
  scope :exclude_disabled_function, ->{
    where.not(flag: FLAG_HIDDEN)
  }
  
  scope :relate_functions, ->(list){
    conds = []
    list.each do |fn|
      md, ev = fn.split(".",2)
      unless ev.nil?
        conds << "(module_name = '#{md}' and event_name = '#{ev}')"
      else
        conds << "(module_name = '#{md}')"
      end
    end
    where(conds.join(" OR "))
  }
  
  def self.module_status(list=[])
        
    unless list.empty?
      rec_count = relate_functions(list).disabled_function.count(0)
      if rec_count <= 0
        return :enabled
      else
        return :disabled
      end
    else
      return :undefined  
    end
    
  end
  
  def self.module_disable_or_enable(list,enable=true)
    
    unless list.empty?
      rec_count = relate_functions(list).count(0)
      if rec_count > 0
        if enable
          flg = ""
        else
          flg = FLAG_HIDDEN
        end
        relate_functions(list).update_all(flag: flg)
      end
    end
    
  end
  
  def disabled?
    return self.flag == FLAG_HIDDEN
  end
  
  def module_display_name
    
    self.module_name.gsub("_"," ").capitalize
    
  end
  
  def event_display_name
    
    return self.description
    
  end
  
  def indent_count
    
    return self.order_no.to_s.count(".")
  
  end
  
  def got_permission?(role_id)
    
    return (self.permissions.where({role_id: role_id}).count > 0)
  
  end
  
  def events
    
    unless defined?(@events)
      @events = Privilege.exclude_disabled_function.where(module_name: self.module_name).order(:order_no).all
    end
    
    @events
    
  end
  
end
