class TableInfo < ActiveRecord::Base
  
  def idxfrac
    
    return (self.index_length.to_f/self.data_length.to_f).round(2)
    
  end
  
  def total_size
    
    return (self.data_length.to_i + self.index_length.to_i)
  
  end

end
