class ExportLog < ActiveRecord::Base
  
  belongs_to    :export_task
  
  serialize :condition_string, JSON
  serialize :result_string, JSON
  
  scope :find_by_digest, ->(di){
    where({ digest_string: di })
  }
  
  scope :only_success, ->{
    where({ status: 'S' })  
  }
  
  def status_name
    
    case self.status
    when 'S'
      return "Success"
    when 'F'
      return "Failed"
    end
    
    return 'Undefinded'
    
  end
  
  def result
    
    return self.result_string
  
  end
  
end
