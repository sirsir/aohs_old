class Extension < ActiveRecord::Base
  
  has_paper_trail
  
  has_one     :computer_info
  has_one     :current_computer_status, through: :computer_info  
  has_many    :dids
  belongs_to  :user
  belongs_to  :location_info, foreign_key: :location_id
  
  accepts_nested_attributes_for :dids, allow_destroy: true, reject_if: proc { |attributes|
    attributes['number'].blank?
  }
  
  accepts_nested_attributes_for :computer_info, allow_destroy: true, reject_if: proc { |attributes|
    attributes['ip_address'].blank? and attributes["computer_name"].blank?
  }
  
  scope :order_by, ->(p) {
    incs = []
    order_str = resolve_column_name(p)
    incs << :did if order_str.match(/(dids)/)
    incs << :computer_info if order_str.match(/(computer_info)/)
    incs << :location_info if order_str.match(/(location_info)/)
    includes(incs).order(order_str)
  }

  scope :computer_name_like, ->(p){
    joins(:computer_info).where(["computer_infos.computer_name LIKE ?",p])
  }
  
  scope :computer_ip_like, ->(p){
    joins(:computer_info).where(["computer_infos.ip_address LIKE ?",p])
  }
  
  scope :dids_cont, ->(p){
    dids = Did.select("extension_id").where(["number LIKE ?",p]).all
    dids = dids.map { |d| d.extension_id }
    dids << 0
    where(["id IN (?)",dids])
  }

  scope :specific_user, ->{
    where("extensions.user_id IS NOT NULL AND EXISTS (SELECT 1 FROM users WHERE users.id = extensions.user_id AND users.state = '#{STATE_ACTIVE}')")  
  }

  validates :number,
                presence: true,
                uniqueness: true,
                numericality: true,              
                length: {
                  minimum: 4,
                  maximum: 10
                }
                
  validates_associated  :dids
  validates_associated  :computer_info
                
  validates_uniqueness_of :number,
                allow_blank: true,
                allow_nil: true
     
  def extension_number
    self.number
  end

  def extension_id
    self.extension_id
  end

  def ip_address
    get_computer_info.ip_address
  end

  def computer_name
    get_computer_info.computer_name
  end

  def location_name
    get_location_info.name
  end
  
  def did_number
    (self.dids.map { |d| d.number }).join(", ") rescue nil
  end

  def last_logged_user
    ccs = self.current_computer_status
    unless ccs.nil?
      ccs.login_name
    else
      nil
    end
  end
  
  def last_logged_time
    ccs = self.current_computer_status
    unless ccs.nil?
      ccs.check_time
    else
      nil
    end
  end
  
  def did_list
    [] #self.dids
  end
  
  def do_build
    did_count = 2 - self.dids.count(0)
    if did_count > 0
      did_count.times { |t| self.dids.build }
    end
    if self.computer_info.nil?
      self.build_computer_info
    end
  end
  
  def get_computer_info
    unless defined?(@computer_info)
      @computer_info = self.computer_info
      @computer_info = ComputerInfo.new if @computer_info.nil?
    end
    @computer_info
  end

  def get_location_info
    unless defined?(@location_info)
      @location_info = self.location_info
      @location_info = LocationInfo.new if @location_info.nil?
    end
    @location_info
  end
  
  def update_computer_info(params={})
    comp_ip = params[:ip_address]
    comp_name = params[:computer_name]
    
    comp_x = ComputerInfo.where(ip_address: comp_ip).first
    if comp_x.nil?
      comp_x = self.computer_info
      if comp_x.nil?
        comp_x = ComputerInfo.new({ extension_id: self.id })
      end
    else
      comp_x.extension_id = self.id
    end
    
    unless comp_x.nil?
      comp_x.ip_address = comp_ip
      comp_x.computer_name = comp_name
      comp_x.save
    end
    
    return comp_x
  end
  
  def update_dids_info(params=[])
    dids = params[:did]
    dids = [dids] unless dids.is_a?(Array)
    dids_o = Did.where(["number IN (?) OR extension_id = ?", dids, self.id]).all
    unless dids_o.empty?
      dids_o.delete
    end
    dids.uniq.each do |d|
      did = Did.new({ extension_id: self.id, number: d })
      did.save
    end
  end
  
  private
  
  def self.resolve_column_name(str)
    unless str.empty?
      if str.match(/(extension)/)
        str = str.gsub("extension","extensions.number")
      end
      if str.match(/(computer_ip)/)
        str = str.gsub("computer_ip","computer_infos.ip_address")
      end
      if str.match(/(computer_name)/)
        str = str.gsub("computer_name","computer_infos.computer_name")
      end
      if str.match(/(location)/)
        str = str.gsub("location","location_infos.name")
      end
    end
    return str
  end  

  def self.ransackable_scopes(auth_object = nil)
    %i(computer_name_like computer_ip_like dids_cont)
  end

end
