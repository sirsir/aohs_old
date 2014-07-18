class GroupsController < ApplicationController

  layout "control_panel"

  before_filter :login_required
  before_filter :permission_require

  def index 
    
    sort_key = groups_order
    sort_key = "#{sort_key} #{params[:sort]}"

    @group_category_type_names = GroupCategoryType.order('order_id asc').all.map{|gct| gct.name}

    #######################################################
    # =>                    Filter                     <= #
    #######################################################
    @filter_enable = false
    @type = GroupCategoryType.all

    @filters = []
    @added_fltr = Hash.new("")
    @select_fltr = Hash.new("")
    @type.each_with_index do |typ, idx|
      # filter for each type <<use in added filter>>
      @filters[idx] = GroupCategory.where(:group_category_type_id => typ.id)
      # Create Hash
      @added_fltr[typ.name.downcase.to_s.to_sym] = false
    end

    # Begin : Search
    group = Group.select(:id).all
    group_id = group.map {|g| g.id}

    unless group_id.empty?
      if params.has_key?(:name) and not params[:name].empty?
        group = Group.where("name like '%%#{params[:name]}%%'")
        group_id = group.map {|g| g.id}
      end

      if params.has_key?(:leader) and not params[:leader].empty?
        usr_id = Manager.select(:id).where("display_name like '%%#{params[:leader]}%%'")
        group = Group.where(:leader_id => usr_id.map{|u| u.id})
        group_id = group.map {|g| g.id}
      end

      if params.has_key?(:category) and not params[:category].empty?
        all_cat = params[:category].split(",")
        all_cat.each do |cat|
          gtp_cat_id = GroupCategory.where(:value => cat).first
          group = Group.joins(:group_categorizations).where(:group_categorizations => {:group_category_id => gtp_cat_id.id}, :id => group_id)

          group_id = group.map {|g| g.id}
          @added_fltr[gtp_cat_id.category_type.name.downcase.to_s.to_sym] = true
          @select_fltr[gtp_cat_id.category_type.name.downcase.to_s.to_sym] = cat
        end
      end
    end
    # End : Search


    if group_id.empty?
      @filter_enable = false
    else
      @filter_enable = true
    end

    @page = 1
    @page = params[:page] if params.has_key?("page") and not params[:page].empty?

    @page = default_page(params[:page])

    @groups = Group.includes([:categories, :leader]).where(:id => group_id).order(sort_key)
    @groups = @groups.paginate(:page => params[:page],:per_page => $PER_PAGE)

    @filter_enable = false if not $FILTER_SHOW_ENA

  end

  def new

    @group_category_types = GroupCategoryType.order('order_id asc')

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
      @group = Group.where(:id => params[:id]).first
      @group_category_types = GroupCategoryType.order('order_id asc')
      @group_categorize = GroupCategorization.where(:group_id => params[:id])
    rescue => e
      log("Edit","Group",false,",ID:#{params[:id]}, #{e.message}")
      redirect_to :controller => "groups",:action => "index"
    end

  end

  def create

    @group_category_types = GroupCategoryType.order('order_id asc')
    @group_categorize = GroupCategorization.where(:group_id => params[:id])

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

     @group = Group.where(:id => params[:id]).first
     @group_category_types = GroupCategoryType.all
     @group_categorize = GroupCategorization.where(:group_id => params[:id])

     if @group.update_attributes(params[:group])
        old_gct = GroupCategorization.select(:id).where(:group_id => @group.id)

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

      group = Group.where(:id => params[:id]).first

      if can_delete(group.id)
        if Group.destroy(group.id)
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

     users = Agent.alive.where(:group_id => id).all
     if users.empty?
        return true
     else
        return false
     end

   end

   def show

      @group = Group.where(:id => params[:id]).first
      @group_category_type_names = GroupCategoryType.all.map{ |gct| gct.name }
      @agents = Agent.alive.where(:group_id => @group.id).all

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @group }
      end

   end

   def get_members

     group_id = params[:id]

     g = Group.where(:id => group_id).first
     unless g.nil?
       usrs = User.alive.where(:group_id => g.id).order
       unless usrs.empty?
         
       end
     end

   end

   protected

  def groups_order
    sort_key = nil
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
    return sort_key
  end

end
