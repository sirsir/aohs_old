
# contains functions that use in Applications and Views/Helper

module Format

   def format_sec(sec, short = false)
      sec = sec.to_i
       
      if short
         unit = ["h", "m", "s"]
      else
         unit = [" hour", " min", " sec"]
      end

      format = []
      hour = sec / 3600

      if hour > 0
         if hour < 10
          format << "0#{hour}"
         else
          format << "#{hour}"
         end
         sec %= 3600
      end

      min = sec / 60
      if min > 0
         if min < 10
          format << "0#{min}"
         else
          format << "#{min}"
         end
         sec %= 60
      else
        format << "00"
      end

      if sec < 10
        format << "0#{sec}"
      else
        format << "#{sec}"
      end

      format.join(":")

   end

  def is_numeric(str)

    if ((str.to_s).gsub(/^[0-9]+$/,'')).strip.length <= 0
      return true
    else
      if str.length <= 4
        return true
      else
        return false
      end
    end
    
  end

  def audio_src_path(src)

    if $AUDIO_BASE_URL.blank? or $AUDIO_BASE_URL.length < 5
      return src
    else
      return File.join($AUDIO_BASE_URL,src)
    end  
    
  end

  def number_with_delimiter(number, delimiter=",", default = 0)

    return number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")

  end

  def float_with_delimiter(number, delimiter=",", default = "0.00")
     
     if number.nil?
       return default
     else
       number = sprintf("%0.2f",number.to_f).to_s.split(".")
       return number[0].to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}") + "." + number[1].to_s
     end
    
   end
       
  def reverse_format_string(format_string)
      tmp = format_string.split(':')
      limit = tmp.length
      if limit == 3
         t1 = tmp[0].to_i * 3600 + tmp[1].to_i * 60 + tmp[2].to_i
      elsif limit == 2
         t1 = tmp[0].to_i * 60 + tmp[1].to_i
      elsif limit == 1
         t1 = tmp[2].to_i
      else
         t1 = 0
      end
      return t1
  end
  
  def get_base_url()

     host = request.raw_host_with_port()
     
     if request.path().to_s() == request.request_uri().to_s()
       return request.path().to_s()
     else
       return request.request_uri().to_s()
     end

  end

  def null_to_value(obj,value=nil)

    if not obj.nil? and not obj.empty?
      return obj
    else
      if value.nil?
        return ""
      else
        return value
      end
    end
    
  end
  
  def percentage_val(val,all)
    val = val.to_f
    all = all.to_f
    if all <= 0
      return 0.00
    else
      return (val/all)*100.0
    end
  end
    
  def blk(val,default="-")
    return (val.blank? ? default : val)
  end
  
  def blkd(val,fm="%Y-%m-%d %H:%M:%S",default="-")
    return val.blank? ? default : val.strftime(fm) 
  end
  
  def check_order_name(sort,default="asc")
    return (["asc","desc"].include?(sort) ? sort : default)
  end
  
  def row_no(i,page,per_page)
    page = 1 if page.to_i <= 0
    return (i+1) + (per_page * (page.to_i-1))
  end
  
end
