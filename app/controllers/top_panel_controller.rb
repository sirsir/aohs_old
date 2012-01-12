class TopPanelController < ApplicationController

   before_filter :login_required

   include AmiReport
   
   def index

     @calls_browser_url = AmiConfig.get("client.aohs_web.callBrowserShotcut")
     @min_update_report_today = AmiConfig.get("client.aohs_web.autoUpdateReportToday")
     
   end

   def statistics_today
      
      with_my_agents = true
                
      # today all agent
      rs = find_report_today({:with_agent => permission_by_name('tree_filter')})
        
      rs_all = rs[:all]
      rs_my = rs[:my]
      rs_my_all = rs[:my_all]
        
      result = { :all => nil, :my => nil, :my_all => nil, :date => Time.new.strftime("%Y-%m-%d %H:%M:%S") }
      
      unless rs_all.nil?
        result[:all] = {
          :agents => number_with_delimiter(rs_all[:agents]),
          :calls => number_with_delimiter(rs_all[:calls]),
          :inbound => number_with_delimiter(rs_all[:inbound]),
          :outbound => number_with_delimiter(rs_all[:outbound]),
          :duration => format_sec(rs_all[:duration]),
          :ngwords => number_with_delimiter(rs_all[:ngwords]),
          :mustwords => number_with_delimiter(rs_all[:mustwords]),         
          :agent => rs_all[:avg_agent],
          :avg_call => number_with_delimiter(rs_all[:avg_call]),
          :avg_inbound => number_with_delimiter(rs_all[:avg_inbound]),  
          :avg_outbound => number_with_delimiter(rs_all[:avg_outbound]),  
          :avg_duration => format_sec(rs_all[:avg_duration]),            
          :avg_mustword => float_with_delimiter(rs_all[:avg_mustword]),            
          :avg_ngword => float_with_delimiter(rs_all[:avg_ngword])               
        }
      end
      
      unless rs_my.nil?
        result[:my] = {
          :agents => number_with_delimiter(rs_my[:agents]),
          :calls => number_with_delimiter(rs_my[:calls]),
          :inbound => number_with_delimiter(rs_my[:inbound]),
          :outbound => number_with_delimiter(rs_my[:outbound]),  
          :duration => format_sec(rs_all[:duration]),
          :ngwords => number_with_delimiter(rs_my[:ngwords]),
          :mustwords => number_with_delimiter(rs_my[:mustwords]),         
          :agent => rs_my[:avg_agent],
          :avg_call => number_with_delimiter(rs_my[:avg_call]),
          :avg_inbound => number_with_delimiter(rs_my[:avg_inbound]),  
          :avg_outnbound => number_with_delimiter(rs_my[:avg_outbound]),             
          :avg_duration => format_sec(rs_my[:avg_duration]),         
          :avg_mustword => float_with_delimiter(rs_my[:avg_mustword]),            
          :avg_ngword => float_with_delimiter(rs_my[:avg_ngword])               
        }        
      end

     unless rs_my_all.nil?
       result[:my_all] = { 
         :agents => "#{float_with_delimiter(rs_my_all[:agents])}%",
         :calls => "#{float_with_delimiter(rs_my_all[:calls])}%",
         :inbound => "#{float_with_delimiter(rs_my_all[:inbound])}%",
         :outbound => "#{float_with_delimiter(rs_my_all[:outbound])}%",
         :duration => "#{float_with_delimiter(rs_my_all[:duration])}%",            
         :mustwords=> "#{float_with_delimiter(rs_my_all[:mustwords])}%",            
         :ngwords  => "#{float_with_delimiter(rs_my_all[:ngwords])}%"              
       }        
     end
                         
      render :json => result

   end 

end
