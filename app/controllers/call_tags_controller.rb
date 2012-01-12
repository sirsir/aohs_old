class CallTagsController < ApplicationController

  layout "control_panel"

  before_filter :login_required
  before_filter :permission_require, :except => [:tags]
  
  def index

    order_by = "asc"
    case params[:by]
      when /(asc)/
        order_by = "desc"
      when /(desc)/
        order_by = "asc"
    end
    params[:by] = order_by
        
    case params[:sort]
      when "name"
        sort_key = "name #{order_by}"
      when "calls"
        sort_key = "count(taggings.id) #{order_by}"
    end

    conditions = []
    if params.has_key?(:tag) and not params[:tag].empty?
      conditions << "tags.name like '#{params[:tag]}%%'"
    end

    @filter_enable = true unless conditions.empty?
    @tag_group = nil
    
    if params.has_key?(:group_id) and not params[:group_id].empty?
      conditions << "tag_group_id = #{params[:group_id]}"
      @tag_group = TagGroup.find(params[:group_id])
    end
  
    @call_tags = Tags.paginate(
                :page => params[:page],
                :per_page => $PER_PAGE,
                :include => [:taggings,:tag_group],     
                :order => sort_key,
                :group => "tags.id",
                :conditions => conditions)

    @tag_groups = TagGroup.find(:all,:order => 'name')

    @filter_enable = false if not $FILTER_SHOW_ENA
    
  end

  def new

    @tag_group_id = TagGroup.find(params[:group_id]).id if params[:group_id].to_i > 0

    @tags = Tags.new()

    if TagGroup.count(:id) <= 0
      flash[:error] = "Group of tag not found. Plead add new group tag before add tag."
      redirect_to :action => 'index'
    end

  end

  def create

    @tags = Tags.new(params[:tags])

    begin
      if @tags.save
          log("Add","CallTag",true,"id:#{@tags.id}, name:#{@tags.name}")
          redirect_to :action => 'index',:group_id => @tags.tag_group_id
      else
          log("Add","CallTag",false,@tags.errors.full_messages)
          flash[:message] = @tags.errors.full_messages
          render :action => 'new'
      end
    rescue => e
        log("Add","CallTag",false,e.message)
        flash[:error] = "Add tag has been failed.[#{e.message}]"
        redirect_to :action => 'index'
    end
    
  end

  def edit

    begin
      
      @tags = Tags.find(params[:id])
        
    rescue => e
      
      log("Edit","CallTag",false,"id:#{params[:id]},#{e.message}")
      redirect_to :action => 'index'
      
    end

  end

  def update

    begin
      @tags = Tags.find(params[:id])

      if @tags.update_attributes(params[:tags])
          log("Update","CallTag",true,"id:#{params[:id]}, tag:#{@tags.name}")
          redirect_to :action => 'index' ,:group_id => @tags.tag_group_id
      else
          log("Update","CallTag",false,"id:#{params[:id]}, #{@tags.errors.full_messages}")
          flash[:message] = @tags.errors.full_messages
          render :action => 'edit'
      end
    rescue => e
      log("Update","CallTag",false,"id:#{params[:id]}, #{e.message}")
      flash[:error] = "Update tag has been failed.[#{e.message}]"
      redirect_to :action => 'index'
    end
    
  end

  def delete

    begin
      
      tags = Tags.find(params[:id])
      if can_delete?(tags.id)
        tags.destroy
        Taggings.delete_all({:tag_id => params[:id]})
        log("Delete","CallTag",true,"id:#{params[:id]}, tag:#{tags.name}")
      else
        log("Delete","CallTag",false,"id:#{params[:id]}, tag:#{tags.name}, delete was cancelled.")
      end
      
    rescue => e
      
      log("Delete","CallTag",false,"id:#{params[:id]}, #{e.message}")
      flash[:error] = "Delete tag has been failed.[#{e.message}]"   
        
    end

    redirect_to :action => 'index'

  end

  def can_delete?(tag_id)

    return true
    
  end

  def tags

    tag_groups = []
    voice_id = params[:voice_id].to_i if not params[:voice_id].blank?
    jtags = []
    
    if voice_id.to_i > 0
      tags = Tagging.find(:all,:conditions => {:taggable_id => voice_id},:group => :tag_id)
      tags_id = tags.map { |t| t.tag_id }
      tag_groups = TagGroup.find(:all,:joins => :tags,:conditions => {:tags => {:id => tags_id}},:order => 'tag_groups.name,tags.name',:group => :name) unless tags_id.blank?
      unless tag_groups.blank?
         tag_groups.each do |tg|
           jtags << {:name => tg.name , :tags => (tg.tags.map { |t| tags_id.include?(t.id) ? "#{t.id},#{t.name}" : nil }).compact}
         end
      end      
    else
      tag_groups = TagGroup.find(:all,:include => :tags,:order => 'tag_groups.name,tags.name')
      unless tag_groups.blank?
         tag_groups.each do |tg|
           jtags << {:name => tg.name , :tags => tg.tags.map { |t| "#{t.id},#{t.name}" }}
         end
      end
    end

    render :text => jtags.to_json
    
  end

  # for 'voice_logs/shows/...' page
  def load_tags

    tag_info = []
    voice_log_id = params[:voice_id]
    tags = Tags.find(:all, :joins => :tag_group, :order => 'tag_groups.name,tags.name')

    tags.each do |tag|
      tagging = Tagging.find(:first, :conditions => {:taggable_id => voice_log_id, :tag_id => tag.id})
      if not tagging.nil?
        tag_info << {:tag_id => tag.id, :tag_name => tag.name, :tag_group => tag.tag_group.name, :status => "checked"}
      else
        tag_info << {:tag_id => tag.id, :tag_name => tag.name, :tag_group => tag.tag_group.name, :status => ""}
      end

    end

    render :json => tag_info
  end

end
