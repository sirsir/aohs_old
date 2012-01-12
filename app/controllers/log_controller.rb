class LogController < ApplicationController

   layout "control_panel"

   before_filter :login_required,:permission_require

   def index

      @application_list = Logs.select('application').group('application').all
      unless @application_list.empty?
        @application_list = (@application_list.map { |a| a.application }).compact
        unless @application_list.empty?
          if @application_list.length <= 1
            @application_list = []
          end
        end
      end
      
      if params.has_key?(:col)
        case params[:col]
        when /date/:
          sort_key = 'start_time'
        when /user/:
          sort_key = 'user'
        when /act/
          sort_key = "name"
        when /status/
          sort_key = "status"
        when /ip/
          sort_key = "remote_ip"
        when /target/
          sort_key = "target"
        else
          sort_key = 'start_time'
       end
      else
        sort_key = 'start_time'
      end

      order = "#{sort_key} #{check_order_name(params[:sort],"desc")}" 
     
      @status = Logs.select('status').group('status')
      @actions = Logs.select('name').group('name')
      
      conditions = []
      starting = ""
      ending = ""

       if params.has_key?(:st_date) and not params[:st_date].empty?
         if params.has_key?(:st_time) and not params[:st_time].empty?
           starting = "#{params[:st_date].to_date} #{params[:st_time]}"
         else
           starting = "#{params[:st_date].to_date.to_s} 00:00:00"
         end
       end
     
       if params.has_key?(:ed_date) and not params[:ed_date].empty?
         if params.has_key?(:ed_time) and not params[:ed_time].empty?
           ending = "#{params[:ed_date].to_date} #{params[:ed_time]}"
         else
           ending = "#{params[:ed_date].to_date.to_s} 23:59:59"
         end
       end

       if params.has_key?(:act) and not params[:act].empty?
         conditions << "name like '#{params[:act]}%'"
       end

     if not starting.empty? and not ending.empty?
       conditions << "start_time between '#{starting}' and '#{ending}'"
     elsif not starting.empty? and ending.empty?
       conditions << "start_time >= '#{starting}'"
     elsif starting.empty? and not ending.empty?
       conditions << "start_time <= '#{ending}'"
     end

     if params.has_key?(:status) and not params[:status].empty?
       conditions << "status = '#{params[:status]}'"
     end

     if params.has_key?(:user) and not params[:user].empty?
       conditions << "user like '%#{params[:user]}%'"
     end

     if params.has_key?(:ip) and not params[:ip].empty?
       conditions << "remote_ip like '%#{params[:ip]}%'"
     end
               
     if params.has_key?(:app) and not params[:app].empty?
       app_name = nil
       case params[:app]
       when /^aohs/: app_name = "AOHS"
       when /^moss/: app_name = "MOSS"
       end
       conditions << "application = '#{app_name}'" unless app_name.nil?
     else
       params[:app] = "all"
     end
         
      @page = ((params[:page].to_i <= 0) ? 1 : params[:page].to_i)
      
      @logs = Logs.order(order).where(conditions.join(" and ")).paginate(:page => params[:page])

  end
  
end