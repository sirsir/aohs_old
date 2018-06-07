require 'digest'

class ExportCondition < ActiveRecord::Base
  
  serialize :condition_string, JSON
  
  belongs_to  :export_task
  
  def conditions
    
    self.condition_string
    
  end
  
  def conv_conditions
    
    return separate_condition
  
  end
  
  private
  
  def separate_condition
    
    result = []
    
    dates   = list_of_date
    times   = list_of_times
    phones  = list_of_phones
    cdir    = call_direction
    cdur    = duration_range
    tags    = list_of_tags
    
    dates.each do |d|
      
      rs = {}
      rs[:date] = d
      
      unless times.empty?
        rs[:times] = times
      end
      
      unless cdir.nil?
        rs[:call_direction] = cdir  
      end
      
      unless cdur.empty?
        rs = rs.merge(cdur)
      end
      
      unless tags.empty?
        rs = rs.merge(tags)  
      end
      
      phones.each do |p|
        rs[:phones] = p
        result << rs.deep_dup
      end

    end
    
    result.each do |r|
      r[:digest] = Digest::MD5.hexdigest r.to_s
    end

    return result

  end
  
  def list_of_date
    
    dates = []
    ft = conditions["date_range"].match(/(\d{4}-\d{2}-\d{2}).*(\d{4}-\d{2}-\d{2})/)
    df = ft[1]
    dt = ft[2]

    (df..dt).each do |d|
      dates << d
    end

    return dates    

  end
  
  def list_of_times
    
    times = []
    ti = conditions["hours"]
    
    ti.each do |t|
      a = t.to_s.match(/(\d{1,2})(-+)(\d{1,2})/)
      if a.nil?
        times << {
          hour_in: t.to_i
        }
      else
        times << {
          hour_from: a[1].to_i,
          hour_to: a[3].to_i
        }
      end
    end
    
    return times

  end

  def list_of_phones

    phones = []
    ph = conditions["phones"].split(",")
    
    px = []
    ph.each do |p|
      px << p.strip
      if px.length >= 50
        phones << px
        px = []
      end
    end
    
    phones << px.sort unless px.empty?
    
    return phones.sort

  end

  def list_of_tags
    
    ret = {}
    
    tg = conditions["tags"].to_s.split(",")
    unless tg.empty?
      tg.sort.each do |t|
        ret[:tags] = [] if ret[:tags].nil?
        ret[:tags] << t     
      end
    end
    
    return ret
  
  end
  
  def call_direction

    case conditions["call_direction"]
    when "i", "o"
      return conditions["call_direction"]
    end
    
    return nil
  
  end
  
  def duration_range

    ret = {}
    
    dfrom = conditions["duration_from"]
    dto = conditions["duration_to"]
    
    if not dfrom.nil? and dfrom.to_i > 0
      ret[:duration_from] = dfrom.to_i
    end
    
    if not dto.nil? and dto.to_i > 0
      ret[:duration_to] = dto.to_i
    end
    
    return ret
  
  end

end