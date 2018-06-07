class OperationLog < ActiveRecord::Base
  
  TYPES = {
    :info   => "INFO",
    :warn   => "WARNING",
    :error  => "ERROR"
  }
  
  scope :last_six_months, -> {
    where(["created_at >= ?",6.months.ago])
  }
  
  scope :created_at_betw, ->(from_date,to_date) {
    where(["created_at BETWEEN ? AND ?",from_date,to_date])
  }
  
  scope :access_history, ->(usrn) {
    where(created_by: usrn, module_name: 'Session')
  }
  
  scope :order_by, ->(p) {
    
    incs      = []
    order_str = resolve_column_name(p)
    
    includes(incs).order(order_str)
    
  }

  def event_type2
    
    self.event_type.to_s.capitalize  
  
  end

  private
  
  def self.resolve_column_name(str)
    
    unless str.empty?
      
    end
    
    str
    
  end

  def self.ransackable_scopes(auth_object = nil)
    
    %i(created_at_betw access_history)
  
  end

end
