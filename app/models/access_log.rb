class AccessLog < ActiveRecord::Base

  def self.update_access_logs(login_name,mac_address,remote_ip,srcs=[])
  
    succ_count = 0
    
    if not login_name.nil? and not mac_address.nil?
    
      unless srcs.empty?
        srcs.each do |src|
          ui = {
            :last_access_time => src[:access_time],
            :url => src[:url],
            :count => src[:count].to_i,
            :login_name => login_name,
            :remote_ip => remote_ip,
            :mac_address => mac_address
          }
          ui = create(ui)
          if ui
            succ_count += 1
          end
        end
      end
        
    end
    
    return succ_count
    
  end
      
end
