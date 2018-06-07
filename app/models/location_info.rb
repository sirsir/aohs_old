class LocationInfo < ActiveRecord::Base
  
  has_many    :extensions

  def self.available?
    count(0) > 0  
  end
  
  def self.location_options(opts={})
    records = self.order(:name)
    
    # check access control
    if opts[:user_id].present?
      sites = UserAttribute.where(user_id: opts[:user_id]).attr_name(:locations).first.attr_val.split("|").map { |lc| lc.to_i } rescue []
      unless sites.empty?
        records = records.where(id: sites)
      end
    end
    
    return records.all.map { |o| [o.name,o.id] }
  end
  
  def available
    @available = true  
  end
  
  def not_available
    @available = false
  end
  
  def available?
    @available == true
  end
  
end
