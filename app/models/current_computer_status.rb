class CurrentComputerStatus < ComputerLog
  
  self.table_name = "current_computer_status"
  
  scope :ndays_ago, ->(n){
    where(["check_time >= ?", Date.today - n.days])  
  }
  
  def computer_logoff?
    return ["logoff","shutdown"].include?(self.computer_event.to_s.downcase.strip)
  end
  
end