module ExportCallsHelper
  
  def icon_status(name)
    
    case name.downcase
    when "new", "not ready"
      return 'question'
    when "wait"
      return 'clock-o'
    when "exporting"
      return 'spinner'
    when "failed"
      return ''
    when "deleted"
      return 'exclamation-triangle'
    else
      return 'check-circle-o'
    end
    
  end
  
end
