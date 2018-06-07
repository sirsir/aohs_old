class UserAttribute < ActiveRecord::Base
  
  #
  # fixed user attributes
  #
  
  C_UNKNOWN_CALL        = 1     # code 1 = call - unknown agent
  C_ALL_GROUP           = 2     # code 2 = call - all groups
  C_LOCATIONS           = 3     # list of site-id
  C_SHOW_AUDIO_WAVE     = 10
  C_SAMACCOUNTNAME      = 21    # ldap
  C_DN                  = 22    # ldap
  C_MEMBER_OFF          = 23    # ldap
  C_BRANCH_CODE          = 102    # ldap
  C_REGION_CODE          = 103    # ldap

  has_paper_trail
  
  belongs_to  :user
  
  scope :attr_name, ->(n){
    case n.to_sym
    when :unknown_call
      where(attr_type: C_UNKNOWN_CALL)
    when :all_groups
      where(attr_type: C_ALL_GROUP)
    when :locations
      where(attr_type: C_LOCATIONS)
    when :audio_wave
      where(attr_type: C_SHOW_AUDIO_WAVE)
    when :branch_code
      where(attr_type: C_BRANCH_CODE)
    when :region_code
      where(attr_type: C_REGION_CODE)
    else
      where(attr_type: -1)
    end 
  }
  
  scope :find_by_user_and_type, ->(user_id, attr_type){
    where(user_id: user_id, attr_type: attr_type)
  }
  
  scope :attr_type, ->(id){
    where(attr_type: id)  
  }
  
  def self.custom_attributes
    ds = AppUtils::DataSource.load(:user_attributes)
    cust_attr = []
    unless ds.data.nil?
      ds.data.each do |k, v|
        v["name"] = k
        unless v["source"].nil?
          v["values"] = SystemConst.options_for(v["source"])
        end
        cust_attr << v
      end
    end
    return cust_attr
  end
  
  def self.name_type_to_id(name_type)
    attrs = custom_attributes.select { |ax| (ax["source"].to_s == name_type.to_s) || (ax["name"].to_s == name_type.to_s) }
    unless attrs.empty?
      return attrs.first["id"]
    end
    return nil
  end
  
  def self.update_ldap_info(user_id, attrs={})  
    create_or_update(user_id, C_DN, attrs[:dn])
    create_or_update(user_id, C_SAMACCOUNTNAME, attrs[:samaccountname])
    create_or_update(user_id, C_MEMBER_OFF, attrs[:memberof])
  end
  
  def self.create_or_update(user_id, attr_id, attr_value)
    attr_id = attr_id.to_i
    attr_value = attr_value.to_s
    ua = UserAttribute.find_by_user_and_type(user_id, attr_id).first
    if ua.nil? and not attr_value.empty?
      ua = UserAttribute.new  
    end
    unless ua.nil?
      unless attr_value.empty?
        ua.user_id = user_id
        ua.attr_type = attr_id
        ua.attr_val = attr_value
        ua.save!
      else
        ua.delete
      end
    end
    return ua
  end

  def is_checked?
    return ((self.attr_val == "false" or self.attr_type.nil?) ? false : true)
  end
  
  private
  
  # end class
end
