class EventController < ApplicationController

   layout "control_panel"

   before_filter :login_required,:permission_require

   def index

     # check sort key
     if params.has_key?("sort")
       case params[:sort]
       when /start_time/:
          sort_key = 'start_time desc'
       when /complete_time/:
          sort_key = 'complete_time desc'
       else
         sort_key = 'start_time desc'
       end
     else
       sort_key = 'start_time desc'
     end
     
     @events = Event.paginate(:page => params[:page], :per_page => $PER_PAGE, :order => sort_key)

     respond_to do |format|
        format.html
     end

   end

 end
