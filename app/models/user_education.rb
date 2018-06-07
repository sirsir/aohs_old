class UserEducation < ActiveRecord::Base
  
  def self.year_list
    
    years = []
    y     = Time.now.year
    
    35.times do |i|
      years << y - i
    end
    
    return years
    
  end
  
  def degree_title
    
    deg = SystemConst.edu_degree(self.degree).first
    unless deg.nil?
      deg.name
    else
      nil
    end
    
  end
  
end
