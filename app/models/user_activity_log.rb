class UserActivityLog < ActiveRecord::Base
  
  def self.update_agent_activities(login_name,mac_address,remote_ip,srcs=[])
    
    succ_count = 0
    
    if not login_name.nil? and not mac_address.nil?
      
      if not srcs.empty?
        srcs.each do |src|
          ua = {
            :start_time => src[:start_time],
            :duration => src[:duration],
            :process_name => src[:process_name],
            :window_title => src[:window_title],
            :login_name => login_name,
            :remote_ip => remote_ip,
            :mac_address => mac_address
          }
          ua = create(ua)
          if ua
            succ_count += 1
          end
        end
      end
      
    end
    
    return succ_count
    
  end
  
end
