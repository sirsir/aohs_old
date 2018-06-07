class ProgramInfo < ActiveRecord::Base
  
  DEFAULT_BG_COLOR = "#FFFFFF"

  strip_attributes    allow_empty: true,
                      collapse_spaces: true
  
  default_value_for   :bg_color,  DEFAULT_BG_COLOR

  validates   :name, presence: true,
                uniqueness: true,
                length: {
                  minimum: 1,
                  maximum: 100
                }
  
  validates   :bg_color, presence: true,
                allow_blank: false,
                allow_nil: false
  
  def self.default_bg_color
    DEFAULT_BG_COLOR
  end
  
  def self.default_info
    df = {
      proc_name: "idle",
      name: "Idle",
      bg_color: "#FFFFFF"
    }
    return new(df)
  end
  
  def self.get_info(name)
    d = where(proc_name: name).first
    unless d.nil?
      return d
    end
    return ProgramInfo.default_info
  end
  
  def bg_color_code
    
    if self.bg_color.to_s.empty?
      ProgramInfo.default_bg_color
    else
      self.bg_color
    end
    
  end
  
  def fg_color_auto
    return AppUtils::ColorTool.oposite_color(self.bg_color)
  end
  
  def content_class  
    return "program-#{self.id}" 
  end
  
  def css_content_class
    return "content-#{content_class}"  
  end

end
