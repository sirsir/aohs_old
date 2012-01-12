class GroupsController < ApplicationController

  layout "control_panel"

  before_filter :login_required
  before_filter :permission_require
  
  def index

     if params.has_key?("col")
       case params[:col]
       when /name/:
          sort_key = 'name'
       when /desc/:
          sort_key = 'description'
       when /leader/
          sort_key = 'users.display_name'
       when /role/
          sort_key = 'roles.name'
       else
         sort_key = 'name'
       end
     else
       sort_key = 'name'
     end
     sort_key = "#{sort_key} #{params[:sort]}"
     
    @group_category_type_names = GroupCategoryType.find(:all,:order =>'order_id asc').map{|gct| gct.name}
    @type = GroupCategoryType.find(:all)
    @filters = []
    @added_fltr = Hash.new("")
    @select_fltr = Hash.new("")
    @type.each_with_index do |typ, idx|
      # filter for each type <<use in added filter>>
      @filters[idx] = GroupCategory.find(:all,
                                         :conditions => {:group_category_type_id => typ.id})
      # Create Hash
      @added_fltr[typ.name.downcase.to_s.to_sym] = false
    end

    # Check filter key
    conditions = []
    if params.has_key?(:name) and not params[:name].empty?
      conditions << "name like '%#{params[:name]}%'"
    end

    if params.has_key?(:leader) and not params[:leader].empty?
      leaders = Manager.find(:all,:select => "id", :conditions => "display_name like '#{params[:leader]}%'")
      if leaders.empty?
        leaders = "-1"
      else
        leaders = (leaders.map{|u| u.id }).join(',')
      end
      conditions << "leader_id in (#{leaders})"
    end

    if params.has_key?(:cate) and not params[:cate].empty?
      key_cate = params[:cate].strip.split(",")
      groups_id = Group.find(:all,:select => :id)
      key_cate.each do |cat|
        gtp_cat_id = GroupCategory.find(:first, :conditions => { :value => cat })
        @added_fltr[gtp_cat_id.category_type.name.downcase.to_s.to_sym] = true
        @select_fltr[gtp_cat_id.category_type.name.downcase.to_s.to_sym] = cat
        
        groups = Group.find(:all,
                    :joins => :group_categorizations, 
                    :conditions => {
                      :group_categorizations => { :group_category_id => gtp_cat_id.id }, 
                      :id => groups_id})
                      
        if groups.empty?
          groups_id = []
          break
        else
          groups_id = groups.map { |c| c.id }
        end
      end
      if groups_id.empty?
        conditions << "id = 0"
      else
        groups_id = groups_id.join(',')
        conditions << "id in (#{groups_id})"
      end
    end
 
    @page = ((params[:page].to_i <= 0) ? 1 : params[:page].to_i)

    @groups = Group.paginate(:page => params[:page],
                             :per_page => $PER_PAGE,
                             :conditions => conditions.join(' and '),
                             :include => [:categories,:leader],
                             :order => sort_key)    
  end

  def new

    @group_category_types = GroupCategoryType.find(:all,:order => 'order_id asc')

    if @group_category_types.empty?
      flash[:error] = "Categroy type not found. Please add categroy type before add new group."
      redirect_to :controller => 'groups', :action => 'index'
    elsif GroupCategory.count(:id).to_i <= 0
      flash[:error] = "Categroy not found. Please add categroy before add new group."
      redirect_to :controller => 'groups', :action => 'index'
    else
      mgs_count = Manager.count(:id,:conditions => "role_id != 1")
      if mgs_count <= 0
        flash[:error] = "Manager list found. Please add manager(s) before add new group."
        redirect_to :controller => 'groups', :action => 'index'
      end
    end

    @group = Group.new

  end

  def edit
    
    begin
      @group = Group.find(params[:id])
      @group_category_types = GroupCategoryType.find(:all,:order => 'order_id asc')
      @group_categorize = GroupCategorization.find(:all,:conditions=>{:group_id => params[:id]})
    rescue => e
      log("Edit","Group",false,",ID:#{params[:id]}, #{e.message}")
      redirect_to :controller => "groups",:action => "index"
    end

  end

  def create

    @group_category_types = GroupCategoryType.find(:all,:order => 'order_id asc')
    @group_categorize = GroupCategorization.find(:all,:conditions=>{:group_id => params[:id]})

    begin

      @group = Group.new(params[:group])
      cate_ids = params[:cate]
      if not cate_ids.nil?
        if @group.save
          group_id = Group.find(:first,:select => 'id',:order => 'id desc').id

          cate_ids.each do |c_id|
            if not c_id.empty?
              gct = GroupCategorization.new(:group_id => group_id,:group_category_id => c_id)
              gct.save
            end
          end
          
          log("Add","Group",true,"id:#{@group.id}, group:#{@group.name}")

          redirect_to :controller => "groups",:action => 'show', :id => group_id
        else

          flash[:message] = @group.errors.full_messages
          log("Add","Group",false,@group.errors.full_messages)

          render :controller => "groups",:action => 'new'
        end
      else

        flash[:message] = @group.errors.full_messages
        log("Add","Group",false,@group.errors.full_messages)
        
        render :controller => "groups",:action => 'new'
      end

    rescue => e

      flash[:notice] = 'Create group have some problem. Please try again.'
      log("Add","Group",false,e.message)
      redirect_to :controller => "groups",:action => "index"

    end

   end

   def update

     @group = Group.find(params[:id])
     @group_category_types = GroupCategoryType.find(:all)
     @group_categorize = GroupCategorization.find(:all,:conditions=>{:group_id => params[:id]})
     
     if @group.update_attributes(params[:group])
        old_gct = GroupCategorization.find(:all,:select => 'id',:conditions => {:group_id => @group.id})

        # delete all and create new
        old_gct.each { |x| GroupCategorization.destroy(x.id) }
        cate_ids = params[:cate]
        cate_ids.each do |c_id|
          if not c_id.empty?
            gct = GroupCategorization.new(:group_id => @group.id,:group_category_id => c_id)
            gct.save
          end
        end
        log("Update","Group",true,"id:#{params[:id]}, group:#{@group.name}")
        flash[:message] = @group.errors.full_messages
        redirect_to :controller => "groups",:action => 'show', :id => params[:id]
     else
        log("Update","Group",false,"id:#{params[:id]}, group:#{@group.name}, #{@group.errors.full_messages}")
        flash[:message] = @group.errors.full_messages
        render :controller => "groups",:action => "edit", :id => params[:id]
     end

   end

   def delete

      group = Group.find(params[:id])
      
      if can_delete(group.id)
        if Group.destroy(group.id)
          gct = GroupCategorization.find(:all,:select => 'id',:conditions => {:group_id => params[:id]})
          gct.each { |x| GroupCategorization.destroy(x.id) }

          log("Delete","Group",true,"id:#{params[:id]}, group:#{group.name}")
          flash[:notice] = "Delete group was successfully."
        else
          log("Delete","Group",false,"id:#{params[:id]}, group:#{group.name}")
          flash[:notice] = "Delete group was failed."
        end
      else
        log("Delete","Group",false,"id:#{params[:id]}, group:#{group.name}, delete was cancelled")
        flash[:error] = "Cannot remove this group because is already using."
      end
      
      redirect_to :controller => "groups",:action => 'index'
      
   end

   def can_delete(id)

     users = User.find(:all,:conditions => {:group_id => id})
      
     if users.empty?
        return true
     else
        return false
     end
     
   end

   def show

      @group = Group.find(params[:id])
      @group_category_type_names = GroupCategoryType.find(:all).map{|gct| gct.name}
      @agents = Agent.find(:all,:conditions => {:group_id => @group.id })
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @group }
      end

   end
  
end
