# == Schema Information
# Schema version: 20100402074157
#
# Table name: customers
#
#  id            :integer(10)     not null, primary key
#  customer_name :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Customer < ActiveRecord::Base

  has_many :customer_numbers, :class_name => "CustomerNumber", :foreign_key => 'customer_id'
  has_many :car_numbers
  has_many :voice_log_customers, :class_name => "VoiceLogCustomer" 
  has_many :voice_logs, :through => :voice_log_customers
  
  validates_length_of         :customer_name, :within => 4..255
  ##validates_uniqueness_of   :customer_name, :message => 'duplicate'
  scope :alive, where("(customers.flag != 'd' or customers.flag is null)")
  
  after_destroy :remove_cust_call_map
  
  def voice_log_count  
    numbers = self.customer_numbers.map { |p| p.number.to_s } 
    numbers = numbers.concat(self.customer_numbers.map { |p| "9" + p.number.to_s }) 
    v = VoiceLogTemp.includes(:voice_log_customer).where(["(ani in (?) or dnis in (?) or voice_log_customers.customer_id = ?)",numbers,numbers,self.id]).count
    @@voice_log_count = v.to_i
  end
  
  def phone_list
    numbers = self.customer_numbers.map { |p| p.number }
    @@phone_list = numbers.join(",")
  end
  
  def cars_list
    
  end
  
  def remove_cust_call_map
    customer_id = self.id  
    if customer_id.to_i > 0
      VoiceLogCustomer.delete_all(:customer_id => customer_id)
      cn = CarNumber.where(:customer_id => customer_id)
      VoiceLogCar.delete(cn)
      CarNumber.delete(cn)
      CustomerNumber.delete_all(:customer_id => customer_id)
    end
  end
  
  def update_calls(voice_logs_id=[])
  
    customer_id = self.id
    
    voice_logs_id.each do |v|
      c = {:customer_id => customer_id, :voice_log_id => v}
      vc = VoiceLogCustomer.where(c).first
      if vc.nil?
        VoiceLogCustomer.new(c).save
      else
        vc.update_attributes(c)
      end
    end
    
  end
  
  def update_phones(phones=[])
    
    customer_id = self.id
    
    # remove empty element
    phones = phones.uniq.compact
    p = []
    phones.each do |x|
      next if x.to_s.strip.empty?
      p << x
    end
    phones = p
    
    unless phones.empty?
      cn = CustomerNumber.where(:customer_id => customer_id).all
      if not cn.empty? and not phones.empty?
        cn.each do |c|
          if not phones.empty?
            c.update_attributes({:customer_id => customer_id, :number => phones.pop})
          else
            c.destroy
          end
        end
      end
      if not phones.empty?
        phones.each do |p|
          CustomerNumber.create({:customer_id => customer_id,:number => p})
        end        
      end
    else
      CustomerNumber.delete_all(:customer_id => customer_id)
    end
    
    return true
    
  end

  def update_carnos(cars=[])
    
    customer_id = self.id
    
    if cars.is_a?(Array)
      STDOUT.puts "ARRAY"
      return update_car_without_id(cars,customer_id)
    else
      STDOUT.puts "HASH"
      return update_car_with_id(cars,customer_id)
    end

    return true
    
  end 
  
  protected
  
  def update_car_with_id(carnos,customer_id)
    
    car_nos = [0]
    if not carnos.nil?
      carnos.each do |id,c|
        c = c.to_s.strip
        next if c.length <= 0
        
        if id.to_i > 0 or id =~ /^new/
          cn = CarNumber.where({:customer_id => customer_id, :car_no => c}).first
          unless cn.nil?
            cn.update_attributes(:flag => nil)
          else
            cn = CarNumber.new({:customer_id => customer_id, :car_no => c}) 
            cn.save
          end
          car_nos << cn.id
        else
          cn = CarNumber.where({:customer_id => customer_id, :id => id}).first
          cn.update_attributes({:car_no => c})
          car_nos << cn.id
        end
  
      end
    end
  
    cn = CarNumber.where(["customer_id = ? and id not in (?)",customer_id,car_nos]).all
    a = cn.length
    unless cn.empty?
      cn.each do |c|
        vlc = VoiceLogCar.where(:car_number_id => c.id).all
        if vlc.empty?
          CarNumber.delete(c)
        else
          c.update_attributes(:flag => Aohs::FLAG_DELETE)
        end
      end
    end    
    
    return true
    
  end
  
  def update_car_without_id(cars,customer_id)
    
    cars = cars.uniq.compact   
    
    # remove empty element
    c = []
    cars.each do |x|
      next if x.to_s.strip.empty?
      c << x
    end
    cars = c
    
    unless cars.empty?
      
      cars.each do |c|
        cn = CarNumber.where(["customer_id = ? AND car_no = ?",customer_id,c]).first
        if cn.nil?
          newc = CarNumber.new({:customer_id => customer_id, :car_no => c})
          newc.save! 
        end
      end
      
      cn = CarNumber.where(["customer_id = ? and car_no not in (?)",customer_id,cars]).all
      unless cn.empty?
        cn.each do |c|
          vlc = VoiceLogCar.where(:car_number_id => c.id).all
          if vlc.empty?
            CarNumber.delete(c)
          end
        end
      end
      
    else
      cn = CarNumber.where(:customer_id => customer_id).all
      unless cn.empty?
        cn.each do |c|
          vlc = VoiceLogCar.where(:car_number_id => c.id).all
          if vlc.empty?
            CarNumber.delete(c)
          end
        end
      end
    end
    
    return true
    
  end
  
end
