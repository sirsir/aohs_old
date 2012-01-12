class AgentsController < ApplicationController

   layout "control_panel"

   before_filter :login_required
   before_filter :permission_require ,:except => [:list, :userlist]

   def index

     sort_key = nil
     # check sort key
     case params[:col]
     when /login/:
        sort_key = 'login'
     when /name/:
        sort_key = 'display_name'
     when /sex/
        sort_key = 'sex'
     when /group/
        sort_key = 'groups.name'
     when /state/
        sort_key = 'state'
     when /expired_date/
        sort_key = 'expired_date'
     when /cti_agent_id/
        sort_key = 'cti_agent_id'    
     when /id_card/
          sort_key = 'id_card'                  
     else
       sort_key = 'login'
     end
     order = "#{sort_key} #{check_order_name(params[:sort])}" 
     
     # check filter key
     
     conditions = []
     if params.has_key?(:login) and not params[:login].empty?
        conditions << "login like '%#{params[:login]}%'"
     end
     if params.has_key?(:name) and not params[:name].empty?
        conditions << "display_name like '%#{params[:name]}%'"
     end
     if params.has_key?(:group) and not params[:group].empty?
       grp = Group.find(:first,:conditions => {:name => params[:group]})
       unless grp.nil?
         conditions << "group_id = #{grp.id}"
       end
     end
     if params.has_key?(:agent_id) and not params[:agent_id].empty?
        conditions << "cti_agent_id like '%#{params[:agent_id].strip}%'"
     end
     if params.has_key?(:id_card) and not params[:id_card].empty?
        conditions << "id_card like '%#{params[:id_card].strip}%'"
     end

     @page = ((params[:page].to_i <= 0) ? 1 : params[:page].to_i)

     @agents = Agent.paginate(:page => params[:page],
                              :per_page => $PER_PAGE,
                              :order => order,
                              :conditions => conditions.join(" and "),
                              :include => 'group')

     @groups = (Group.find(:all, :select => 'name',:order => 'name')).map { |g| g.name }

   end

   def list

     @agents = Agent.find(:all)

     # number of agent to retreive
     number = -1
     unless params[:n].nil?
       number = params[:n].to_i
     end

     # page number
     page = params[:p].to_i unless params[:p].nil?

     agents = []
     if number == -1 or page.nil?
       agents = @agents
     else
       page_offset = page * number
       if @agents.size < page_offset
         page_offset = @agent.size
         number = @agent.size - page_offset
       end
       agents = @agents[page_offset, number]
     end
     all = agents.map{ |agent| [agent.id, agent.display_name].join("\t") }

     respond_to do |format|
       format.html # index.html.erb
       format.xml  { render :xml => @agents }
       format.text { render :text => all.join("\n") }
     end

   end

   def show

      begin
        @agent = Agent.find(params[:id])
        @group = Group.find(:first,:conditions => {:id => @agent.group_id})
        @group_details = []
        @group_category_type_names = GroupCategoryType.find(:all).map{|gct| gct.name}
        unless @group.nil?
        categories = {}
        @group.categories.to_ary.map{|c| categories[c.category_type.name] = c.value }
        @group_category_type_names.each{|category_type_name|
          unless (categories[category_type_name]).nil?
            @group_details << categories[category_type_name]
          else
            @group_details << "-"
          end
        }
        end
      rescue => e

        log("Show","Agent",false,"ID:#{params[:id]},#{e.message}")
        flash[:error] = 'Sorry, Agent cannot be found. Please try again.'

        redirect_to :controller => 'agents',:action => 'index'
        
      end

   end

   def new

      @agent = Agent.new

      grp_count = Group.count(:id)
      if grp_count <= 0
        flash[:error] = "Group list not found. Please add group before add new agent."
        redirect_to :controller => 'agents', :action => 'index'
      end

   end

   def edit

      begin

        @agent = Agent.find(params[:id])

      rescue => e

        log("Edit","Agent",false,"id:#{params[:id]}, #{e.message}")
        flash[:error] = "Sorry, Agent cannot be found. Please try again."
        
        redirect_to :controller => 'agents',:action => 'index'

      end

   end

   def create

      @agent = Agent.new(params[:agent])

      if @agent.save

        @agent = User.find(:first,:conditions => { :login => @agent.login })
        @agent.update_attribute(:state,'active')

        log("Add","Agent",true,"id:#{@agent.id}, name:#{@agent.login}")

        redirect_to :controller => 'agents',:action => 'show', :id => @agent.id
        
      else

        log("Add","Agent",false,@agent.errors.full_messages.compact)
        flash[:message] = @agent.errors.full_messages

        render :controller => 'agents',:action => 'new'
        
      end

   end

   def update

      begin

         @agent = Agent.find(params[:id])
           
         if @agent.update_attributes(params[:agent])
            log("Update","Agent",true,"id:#{params[:id]}, name:#{@agent.login}")
            redirect_to(@agent)
         else
            log("Update","Agent",false,"id:#{params[:id]}, name:#{@agent.login}, #{@agent.errors.full_messages.compact}")
            flash[:message] = @agent.errors.full_messages
            render :controller => 'agents', :action => "edit"
         end

      rescue => e
        
         log("Update","Agent",false,"id:#{params[:id]}, #{e.message}")
         flash[:error] = "Update agent have some problem. Please try again."
         
         redirect_to :controller => 'agents',:action => 'index'
      
      end

   end

   def delete

      begin

        @agent = Agent.find(params[:id])

        if @agent.update_attribute("flag", 1)
            log("Delete","Agent",true,"id:#{params[:id]}, name:#{@agent.login}")
        else
            log("Delete","Agent",false,"id:#{params[:id]}, name:#{@agent.login}, #{@agent.errors.full_messages}")
            flash[:error] = 'Delete agent has been failed.'
        end

      rescue => e
        
        log("Delete","Agent",false,"id:#{params[:id]}, #{e.message}")
        flash[:error] = 'Delete agent has been failed.'

      end

      redirect_to :controller => 'agents',:action => 'index'

   end

   def userlist

      group_id = nil
      if params.has_key?(:group_id) and not params[:group_id].empty?
        group_id = params[:group_id]
      end

      groups = []
      if group_id.nil?
        groups = Group.find(:all, :select => 'id', :conditions => {:leader_id => current_user.id })
      else
        groups = Group.find(:all, :select => 'id', :conditions => {:leader_id => current_user.id, :id => group_id })
      end

      users = []
      unless groups.empty?
         tmp_users = User.find(:all,:select => 'login',:conditions => "group_id in (#{ (groups.map { |g| g.id }).join(',')})",:order => 'login')
         unless tmp_users.empty?
           tmp_users.each_with_index do |u,i|
             users << {
                        :no => i + 1,
                        :name => u.login
                     }
           end
         end
      end

      render :layout => false, :json => users

   end

end
