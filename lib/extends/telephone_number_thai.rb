class TelephoneNumberThai
  
  SPECIAL_NUMBERS   = [
    '1112', # The Pizza 
    '1113', # Bug
    '1124',
    '1133', # TOT
    '1150', # KFC
    '1175', # AIS
    '1506', 
    '1669',
    '1691',
    '1711'  # McDonale
  ]
  
  @@phone_area_codes = nil
  @@list_area_codes = nil
  
  def self.number(number)
    return TelephoneNumberThai.new(number)
  end
  
  def initialize(number)
    # number
    @number = number.to_s
    # actual/real number
    @ac_number = @number.to_s
    # area code
    @area_code = nil
    
    # initial
    remove_special_chars
    preload
  end
  
  def type_number
    
    case true
    when mobile_number?
      return :mobile
    when fixed_line_number?
      return :fixed
    when special_number?
      return :special
    when extension_number?
      return :extension  
    end
    
    return :unknown
  
  end
  
  def type_number_short
    
    # return short name of phone type
    # select 3 characters: FIX, SPE, FIX, MOB, EXT
    
    type = type_number.to_s
    type = type[0,3]

    return type.to_sym

  end

  def formatted_number(separater=false)
      
    case type_number
    when :mobile
      return to_formatted_mobile_number  
    when :fixed
      return to_formatted_fixed_number
    when :extension
      return to_formatted_extension_number
    when :special
      return to_formatted_special_number
    end
    
    return @number
  
  end
  
  def real_number
    
    result = formatted_number
    return @ac_number
  
  end
  
  def mobile_number?
    
    return (not match_mobile_number.nil?)
    
  end
  
  def fixed_line_number?
    
    return (not match_fixed_line_number.nil?)
    
  end
  
  def extension_number?
    
    return (not match_extension_number.nil?)
    
  end
  
  def special_number?
    
    return (not match_spcial_number.nil?)
    
  end
  
  def unknown_format?
    
    return (type_number == :unknown)
    
  end
  
  def area_code
    return @area_code
  end
  
  private  
  
  def preload
    # pre-load initial data for telephone number formatting
    if @@phone_area_codes.nil?
      load_area_codes
    end
  end
  
  def load_area_codes
    @@phone_area_codes = []
    # load from file
    dfile = File.join(Rails.root,'lib','data','telephone.areacode.json')
    if File.exists?(dfile)
      data = JSON.parse(File.read(dfile))
      @@phone_area_codes = data["area_code"]["acss"]
      @@list_area_codes = (@@phone_area_codes.map { |a| a["format"] }).flatten.map { |a| a.to_i }
    end
  end
  
  def match_mobile_number
    
    # 06 xxxx xxxx
    # 08 xxxx xxxx
    # 09 xxxx xxxx
    
    return @number.match(/^(\w*)([689])(\d{8})$/)  
  
  end
  
  def to_formatted_mobile_number
    
    rs = match_mobile_number
    @area_code = get_area_code(rs[1])
    @ac_number = [0,rs[2],rs[3]].join
    
    return [pre_number(rs[1]),0,rs[2],rs[3]].join("")
    
  end
  
  def match_fixed_line_number
    
    # 02 xxx xxxx
    # 03 xxx xxxx
    # 04 xxx xxxx
    # 05 xxx xxxx
    # 07 xxx xxxx
    
    return @number.match(/^(\w*)([23457])(\d{7})$/)
  
  end
  
  def to_formatted_fixed_number
    
    rs = match_fixed_line_number
    @area_code = get_area_code(rs[1])
    @ac_number = [0,rs[2],rs[3]].join
    
    return [pre_number(rs[1]),0,rs[2],rs[3]].join("")
  
  end
  
  def match_spcial_number
    
    # [8,9] xxxx -- spcial number
    
    list = ['', 8, 9]
    list = list.join("|")
    
    result = @number.match(/^(#{list})(\d{4})$/)
    
    if not result.nil? and SPECIAL_NUMBERS.include?(result[2])
      return result
    else
      return nil
    end
    
  end
  
  def to_formatted_special_number
    
    rs = match_spcial_number
    @ac_number = rs[2]
    
    return rs[2]
  
  end
  
  def match_extension_number    
    # [5,6,7] xxxx -- Extension  
    list = ['' ,5, 6, 7]
    list = list.concat(@@list_area_codes)
    list = list.join("|")
    return @number.match(/^(#{list})(\d{4,5})$/)
  end
  
  def to_formatted_extension_number
    
    rs = match_extension_number
    @area_code = get_area_code(rs[1])
    @ac_number = rs[2]
    
    return rs[2]
  
  end
  
  def pre_number(p_number)
    
    p_number = p_number.to_s
  
    unless p_number.empty?
      
      # if last digit is zero, will remove it
      last_digit = p_number[-1,1]
      
      if last_digit == "0"
        p_number = p_number[0,p_number.length-1]
      end
      
      unless p_number.empty?
        p_number = "#{p_number} "
      end
    
    end
    
    return p_number
  
  end
  
  def remove_special_chars
    @number = @number.gsub("#","")
  end
  
  def get_area_code(number)
    area = @@phone_area_codes.select { |a| (a["format"] == number) or (a["format"].is_a?(Array) and a["format"].include?(number)) }
    unless area.blank?
      return area.first["name"]
    end
    return nil
  end
  
end