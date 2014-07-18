class PermissionController < ApplicationController

   layout "control_panel"

   before_filter :login_required,:permission_require

   def index

      @role_id = Role.order('order_no asc').map{ |x| x.id }
      @role_names = Role.order('order_no asc').map{ |x| x.name }
      @privileges = Privilege.order('application asc,order_no asc').each do |privilege|
         privilege.roles.to_ary.each do |role|
            if @role_names.include?(role.name)
               privilege[role.name] = true
            else
               privilege[role.name] = false
            end
         end
      end
      
      @application_list = (Privilege.select('application').group('application').map { |g| g.application }).compact
      unless @application_list.empty?
        if @application_list.length <= 1
          @application_list = []
        end
      end
   end
  
   def manage_role
      
      if params.has_key?(:role_list) and not params[:role_list].empty?
        
        role_list = params[:role_list].split(",")
        
        role_list.each do |order_name|
          order, name = order_name.split("=")
          r = Role.where(:name => name.strip).first
          unless r.nil?
            r.update_attributes(:order_no => order.strip.to_i)
          end
        end
        
      end
      
      @roles = Role.order('order_no asc').all
      
   end
   
  def addpermission
    
#    if params[:add_new_role] != ""
#      @role_create = Role.new(:name=>params[:add_new_role],:description=>"No description")
#      if @role_create.save
#        log("Add","Role",true,"name:#{params[:add_new_role]}")
#        flash[:notice] = 'Role was successfully created.'
#      else
#        log("Add","Role",false,"name:#{params[:add_new_role]}")
#      end
#    else
#    end
  
    @permissiondata = Permission.destroy_all()
    @role_id=0
    @privilege_id=0

    params[:x].each do|key,value|
      @countRound = 1
      @role_id = Role.where({:name => key}).first.id
      value.each do|key,v2|
        @privilege_id = v2
        Permission.create(:role_id=>@role_id,:privilege_id=>@privilege_id )
      end
    end
    
    log("Update","Permission",true)

    flash[:notice] = 'Change permission was successfully.'
    redirect_to :controller => "permission",:action => "index"

  end

end
