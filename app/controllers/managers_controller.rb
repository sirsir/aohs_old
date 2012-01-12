class ManagersController < ApplicationController

   include AmiTree
   layout "control_panel"

   before_filter :login_required
   before_filter :permission_require
   
   def index

     # check sort key
     order = nil     
     case params[:col]
     when /login/:
       order = 'login'
     when /name/:
       order = 'display_name'
     when /sex/
       order = 'sex'
     when /role/
       order = 'roles.name'
     when /state/
       order = 'state'
     when /expired_date/
       order = 'expired_date'
     when /cti_agent_id/
       order = 'cti_agent_id'
     when /id_card/
       order = 'id_card'
     else
       order = 'login'
     end
     order = "#{order} #{check_order_name(params[:sort])}" 
     
     conditions = []
     if params.has_key?(:login) and not params[:login].empty?
        conditions << "login like '%#{params[:login]}%'"
     end
     if params.has_key?(:name) and not params[:name].empty?
        conditions << "display_name like '%#{params[:name]}%'"
     end
     if params.has_key?(:role) and not params[:role].empty?
       role = Role.find(:first,:conditions => {:name => params[:role]})
       unless role.nil?
         conditions << "role_id = #{role.id}"
       end
     end
     if params.has_key?(:agent_id) and not params[:agent_id].empty?
        conditions << "cti_agent_id like '%#{params[:agent_id].strip}%'"
     end
     if params.has_key?(:id_card) and not params[:id_card].empty?
        conditions << "id_card like '%#{params[:id_card].strip}%'"
     end
     if params.has_key?(:status) and not params[:status].empty?
        case params[:status]
        when 'Active'
          state = 'active'
        when 'Inactive'
          state = 'passive'
        else
          state = ''
        end
        conditions << "state = '#{state}'"
     end
               
     @page = ((params[:page].to_i <= 0) ? 1 : params[:page].to_i)

     @managers = Manager.paginate(:page => params[:page],
                                  :per_page => $PER_PAGE,
                                  :conditions => conditions.join(" and "),
                                  :order => order,
                                  :include => ['group','role'])
                                    
     @roles = (Role.find(:all,:order => 'name asc').map { |r| r.name })
       
   end

   def show

     begin
       
        @manager = Manager.find(params[:id])

        handler = GroupMember.find(:all,:conditions=>{:user_id => @manager.id})
        unless handler.blank?
          hcg = []
          handler.each { |x| hcg << x.group_id }
          @group = Group.find(:all,:conditions=>"leader_id = #{@manager.id} or id in (#{hcg.join(",")})")
        else
          @group = Group.find(:all,:conditions => {:leader_id => @manager.id})
        end

        @group_details = []
        @group_category_type_names = GroupCategoryType.find(:all).map{|gct| gct.name}

     rescue => e

        log("Show","Manager",false,"ID:#{params[:id]},#{e.message}")
        flash[:error] = "Manager cannot be found. Please try again. [#{e.message}]"
        
        redirect_to :controller => "managers",:action => "index"

      end

   end

   def new

      @manager = Manager.new
   
   end

   def create

      begin

        @manager = Manager.new(params[:manager])
    
        if @manager.save
          @manager = User.find(:first,:conditions => { :login => @manager.login })
          @manager.update_attribute(:state,'active')

          log("Add","Manager",true,"id:#{@manager.id}, name:#{@manager.login}")
          redirect_to :action => 'show', :id => @manager.id
          
        else

          log("Add","Manager",false,"#{@manager.errors.full_messages}")
          flash[:message] = @manager.errors.full_messages
          
          render :action => 'new'
        end
        
      rescue => e
        
        log("Add","Manager",false,"#{e.message}")
        flash[:error] = "Add new manager has been failed. [#{e.message}]"

        redirect_to :controller => "managers",:action => "index"
        
      end

   end

   def edit
      
      begin

        @manager = Manager.find(params[:id])

        begin
          @src_tree = ami_build_tree('task','false',nil,"false",{:enabled_manager => true, :manager_filter => false,:enabled_mycall => false}).to_json
        rescue => e
          @src_tree = ""
          flash[:error] = "Access level treeview cannot show. Please check groups or category or category type.<br/>#{e.message}"
        end

        sql = ""
        sql << "SELECT gz.group_id,q1.value"
        sql << " FROM group_categorizations gz"
        sql << " LEFT JOIN (SELECT gt.name,gc.value,gc.id"
        sql << " FROM group_category_types gt"
        sql << " LEFT JOIN group_categories gc"
        sql << " ON gc.group_category_type_id = gt.id ORDER BY gt.id) q1"
        sql << " ON gz.group_category_id = q1.id ORDER BY gz.group_id"

        @group_details = GroupCategorization.find_by_sql(sql)

        handler = GroupMember.find(:all,:conditions=>{:user_id => @manager.id})
        @grp_managers = GroupManager.find(:all,:joins => :manager,:conditions => {:user_id => @manager.id})
		tmp_grp_managers = []
		
        groups = Group.find(:all,:select => 'id',:conditions => {:leader_id => @manager.id})
        
        if not handler.empty? or not groups.empty?
          hcg = []
          handler.each do  |x|
            hcg << x.group_id
          end
          groups.each do |g| 
            hcg << g.id
          end
          @handler_group = Group.find(:all,:conditions=>"id in (#{hcg.join(",")})")
          @all_group = Group.find(:all,:conditions =>"id not in (#{hcg.join(",")})")
        else
          @handler_group = []
          @all_group = Group.find(:all)
        end

    rescue => e

      log("Edit","Manager",false,"ID:#{params[:id]},#{e.message}")
      flash[:error] = 'Sorry, This manager id cannot be found.'

      redirect_to :controller => "managers",:action => "index"

    end

   end

   def update

      begin

        @manager = Manager.find(params[:id])

        if @manager.update_attributes(params[:manager])

            log("Update","Manager",true,"id:#{params[:id]}, name:#{@manager.login}")
            redirect_to(@manager)

        else

            log("Update","Manager",false,"id:#{params[:id]}, name:#{@manager.login}, #{@manager.errors.full_messages}")
            flash[:message] = @manager.errors.full_messages
            render :action => "edit"
          
        end

      rescue => e

        log("Update","Manager",false,"id:#{params[:id]}, #{e.message}")
        flash[:error] = "Update manager have some problem. #{e.message}"

        redirect_to :controller => "managers",:action => "index"

      end

   end

   def delete

      begin

        manager = Manager.find(params[:id])
        tmpdisplay_name = manager.display_name

        if can_delete(manager.id)
          if manager.destroy
            log("Delete","Manager",true,"id:#{params[:id]}, name:#{manager.login}")
            flash[:notice] = 'Delete manager has been successfully.'
          else
            log("Delete","Manager",false,"id:#{params[:id]}, name:#{manager.login}, delete was cancelled")
            flash[:error] = 'Delete manager has been failed.'
          end
        else
          log("Delete","Manager",false,"id:#{params[:id]}, id not found")
          flash[:error] = 'Delete manager has been failed. Id not found.'
        end

        redirect_to(managers_url)

      rescue => e

        log("Delete","Manager",false,"id:#{params[:id]}, #{e.message}")
        flash[:error] = "Delete manager have some problem. [#{e.message}]"
        redirect_to :controller => "managers",:action => "index"

      end
      
   end

   def can_delete(manager_id)

     can_delete = true

     grp = Group.find(:first,:conditions => {:leader_id => manager_id})

     if grp.nil?
       can_delete = true
     else
       can_delete = false
     end

     return can_delete

   end

   def manage_group_member

     begin

       group_mem_param = params[:group_mem] if params.has_key?(:group_mem)
       mag_id = params[:id] if params.has_key?(:id)
       manager_list = params[:mglist]
       
       manager = Manager.find(:first,:conditions => {:id => mag_id})
       
       unless mag_id.nil?

         GroupMember.destroy_all(:user_id => mag_id)

         # update group members

         unless group_mem_param.blank?
            group_arr = group_mem_param.split(",")
            group_arr.each_with_index do |grm,i|
              unless GroupMember.exists?({:group_id => grm,:user_id =>mag_id})
                gmm = GroupMember.new(:group_id => grm,:user_id => mag_id)
                gmm.save
              end
            end
         else
                 
         end

         # update manger
         
         GroupManager.delete_all(:user_id => mag_id)

         unless manager_list.nil?
            mgs = manager_list.strip.split(",")
            mgs = mgs.compact.uniq
            unless mgs.empty?
              mgs.each do |mg|
                x = GroupManager.new({:user_id => mag_id,:manager_id => mg}).save
              end
            end
         end

         log("Update","ManagerAccess",true,"id:#{params[:id]}, name:#{manager.login}")
         render :text => 'ok'
         
       else

         log("Update","ManagerAccess",false,"id:#{params[:id]}")
         render :text => 'fail'
         
       end

     rescue => e

         log("Update","ManagerAccess",false,"ID:#{params[:id]},#{e.message}")
         render :text => 'fail'

     end

   end

end