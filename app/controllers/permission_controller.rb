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
    
      pms_roles = []
      
      params[:x].each do |key,value|
         role_name = key.to_s.strip
         role = Role.where(:name => role_name).first 
         unless role.nil?
            pms_roles << role.id
            selected_privileges = []
            current_privileges = []
            pms = value
            pms.each do |key2,value2|
               selected_privileges << value2.to_i
            end
            pmc = Permission.select("role_id, privilege_id").where(:role_id => role.id).all
            pmc.each {|p| current_privileges << p.privilege_id}
            STDOUT.puts "Update Permission - #{role.name}##{role.id} old[#{current_privileges.join(",")}]"
            STDOUT.puts "Update Permission - #{role.name}##{role.id} new[#{selected_privileges.join(",")}]"
            selected_privileges.each do |p|
               pm = Permission.where(:role_id => role.id, :privilege_id => p).first
               if pm.nil?
                  pm = Permission.new({:role_id => role.id, :privilege_id => p})
                  pm.save
               end
            end
            selected_privileges << 0
            Permission.delete_all(["role_id = ? AND privilege_id NOT IN (?)",role.id,selected_privileges])
         end
      end

      unless pms_roles.empty?
         STDOUT.puts "Update Permission - Remove No permission #{pms_roles.join(",")}"
         Permission.delete_all(["role_id NOT IN (?) AND privilege_id > 0",pms_roles])
      end
       
      log("Update","Permission",true)
   
      flash[:notice] = 'Change permission was successfully.'
      redirect_to :controller => "permission",:action => "index"
   
   end

end
