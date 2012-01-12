class AccessLog < ActiveRecord::Base

  def self.update_access_logs(login_name, mac_address, remote_ip, srcs=[])
  
    succ_count = 0
    al_srcs = srcs
    
    if not login_name.nil? and not mac_address.nil?
    
      unless al_srcs.empty?
        al_srcs.each do |src|
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
    
    al_srcs = nil
    
    return succ_count
    
  end

end
