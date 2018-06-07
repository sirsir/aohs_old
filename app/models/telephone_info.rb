class TelephoneInfo < ActiveRecord::Base
  
  # list
  NUMBER_TYPE = [
    { name: 'private', code: 'p', display_name: 'Private', bg_color: '#FFE4E1' },
    { name: 'field_collector', code: 'f', display_name: 'Field Collector', bg_color: '#FFDEAD' },
    { name: 'none', code: 'o', display_name: 'Other', bg_color: '#AFEEEE' },
  ]
  
  has_paper_trail
  
  validates   :number,
                presence: true,
                uniqueness: true,
                length: {
                  minimum: 4,
                  maximum: 20
                }

  scope :find_number, ->(n){
    where(number: n)  
  }
  
  scope :only_private, ->{
    where(number_type: 'p')
  }

  scope :order_by, ->(p) {
    incs = []
    includes(incs).order(resolve_column_name(p))
  }
  
  def self.number_type(name)
    return (NUMBER_TYPE.select { |t| t[:name] == name or t[:code] == name }).first
  end
  
  def self.number_type_options
    return NUMBER_TYPE.map { |t| [t[:display_name], t[:code]] }
  end
  
  def self.style_list
    return NUMBER_TYPE
  end
  
  def type_name
    r = get_type_info
    unless r.nil?
      return r[:name]
    end
    return 'none'
  end
  
  def type_name_display
    r = get_type_info
    unless r.nil?
      return r[:display_name]
    end
    return nil
  end
  
  private
  
  def get_type_info
    ntype = self.number_type.to_s.downcase.strip
    r = (TelephoneInfo.style_list.select { |x| x[:code] == ntype }).first
    return r
  end
  
  def self.resolve_column_name(str)
    str
  end
  
end
