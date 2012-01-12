class CurrentChannelStatus < ActiveRecord::Base
	set_table_name('current_channel_status_2')
  
  def self.table_name_prefix
    return "current_channel_status_"
  end
  
end
