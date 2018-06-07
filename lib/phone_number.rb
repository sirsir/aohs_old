require File.join(Rails.root,'lib','extends','telephone_number_thai')

class PhoneNumber
  
  def self.phone_type(type=nil)
    case type.to_s.downcase
    when "ext", "extension"
      return "EXT"
    when "fixed", "fix", "fixed line"
      return "FIX"
    when "mobile", "mobile phone", "mob"
      return "MOB"
    when "other", "special"
      return "SPE"
    else
      return "UNK"
    end
  end
  
  def initialize(phone)
    @telnum = TelephoneNumberThai.number(phone)
  end
  
  def formatted_s
    fmt_number = @telnum.formatted_number
    if (not Settings.callsearch.show_phone_area) or @telnum.area_code.nil?
      fmt_number
    else
      "(#{@telnum.area_code}) #{fmt_number}" 
    end
  end
  
  def phone_type  
    @telnum.type_number_short
  end
  
  def real_number
    @telnum.real_number
  end
  
  def is_ext?
    @telnum.extension_number?
  end
  
  def is_unknown?
    @telnum.unknown_format?
  end
  
  private
  
end