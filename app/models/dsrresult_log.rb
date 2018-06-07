class DsrresultLog < ActiveRecord::Base
  
  belongs_to    :voice_log
  
  def rec_text
    
    extract_result
     
    return @ret_txt
  
  end
  
  def rec_stime
    
    extract_result
    
    return @ret_stime.to_f.round(4)
  
  end
  
  def rec_etime
    
    extract_result
    
    return @ret_etime.to_f.round(4)
  
  end
  
  private

  def extract_result
    
    if defined? @result
      return true  
    end
    
    @ret_txt    = ""
    @ret_stime  = nil
    @ret_etime  = nil
    
    raw_result  = self.result.to_s
    
    raw_result.split("|").each do |rr|
      ele = rr.split(":")
      @ret_txt << ele.first
      @ret_stime = ele[1] if @ret_stime.nil?
      @ret_etime = ele[1]
    end
    
  end
  
end
