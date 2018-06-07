class ComputerLog < ActiveRecord::Base
  
  after_create :update_current_status
  
  scope :check_date_betw, ->(from_date,to_date) {
    
    where("check_time BETWEEN :from_time AND :to_time",from_time: from_date, to_time: to_date)
  
  }
  
  scope :order_by, ->(p) {
    
    incs      = []
    order_str = resolve_column_name(p)
    
    includes(incs).order(order_str)
    
  }
  
  scope :today, ->{
    
    from_date = Date.today.to_formatted_s(:db) + " 00:00:00"
    to_date = Date.today.to_formatted_s(:db) + " 23:59:59"
    
    where("check_time BETWEEN :from_time AND :to_time",from_time: from_date, to_time: to_date)
    
  }
  
  private
  
  def self.resolve_column_name(str)
    
    unless str.empty?
      
    end
    
    str
    
  end

  def self.ransackable_scopes(auth_object = nil)
    
    %i(check_date_betw)
  
  end
  
  def update_current_status
    
    cond = {
      remote_ip: self.remote_ip
    }
    
    ccs = CurrentComputerStatus.where(cond).first
    if ccs.nil?
      ccs = {
        check_time: self.check_time,
        computer_name: self.computer_name,
        login_name: self.login_name,
        remote_ip: self.remote_ip,
        computer_event: self.computer_event
      }
      CurrentComputerStatus.create(ccs)
    else
      CurrentComputerStatus.where(cond).update_all({
        check_time: self.check_time,
        computer_name: self.computer_name,
        login_name: self.login_name,
        computer_event: self.computer_event
      })
    end

  end
  
end
