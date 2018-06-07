class CurrentChannelStatus < ComputerLog

  self.table_name = "current_channel_status"

  def call_direction_name
    case self.call_direction_name
    when 'i'
      return 'inbound'
    when 'o'
      return 'outbound'
    end
    return ''
  end
  
  def call_status
    call_status = Settings.callbrowser.call_status.to_h
    if call_status.has_key?(self.connected.downcase)
      return call_status[self.connected.downcase]
    end
    return "Unknown Status"
  end
  
  def is_connected?
    return self.connected == "connected"
  end
  
  def is_disconnected?
    return (not is_connected?)
  end
  
end