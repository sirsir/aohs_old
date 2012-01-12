class RoleController < ApplicationController

   layout "control_panel"

   before_filter :login_required,:permission_require

   def new

     @role = Role.new
     
   end

   def create

    @role = Role.new(params[:role])

    if @role.save
      log("Add","Role",true,"id:#{@role.id}, name:#{@role.name}")
      redirect_to :controller => "permission",:action => "index"
    else
      log("Add","Role",false,"#{@role.errors.full_messages}")
      flash[:message] = @role.errors.full_messages
      render :controller => "role",:action => 'new'
    end
     
   end
  
end
