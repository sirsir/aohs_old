class ScheduleInfo < ActiveRecord::Base
  
  scope :find_by_name, ->(name){
    where(name: name)
  }
  
  def self.log(name,data={})
    # update latest status
    schi = ScheduleInfo.find_by_name(name).first
    schi = ScheduleInfo.new if schi.nil?
    schi.name = name
    schi.message = data[:message]
    schi.last_processed_time = Time.now
    schi.save
    # create log
    schi.create_operation_log
  end
  
  def self.info(name,msg,oth={})
    
  end
  
  def create_operation_log
    ds = {
      log_type: OperationLog::TYPES[:info],
      module_name: "Schedule",
      event_type: self.name,
      created_by: "system",
      remote_ip: "0.0.0.0",
      message: self.message
    }
    ol = OperationLog.new(ds)
    ol.save! 
  end
  
end
