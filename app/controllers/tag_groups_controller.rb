class TagGroupsController < ApplicationController

  layout "control_panel"

  before_filter :login_required
  before_filter :permission_require
  
  def new

    @tag_group = TagGroup.new()
    
  end

  def create

    @tag_group = TagGroup.new(params[:tag_group])

    begin
      if @tag_group.save
          log("Add","GroupTag",true,"id:#{@tag_group.id}, name:#{@tag_group.name}")
          redirect_to :controller => 'call_tags', :action => 'index', :group_id => @tag_group.id
      else
          log("Add","GroupTag",false,"id:#{@tag_group.id}, #{@tag_group.name}, #{@tag_group.errors.full_messages}")
          flash[:message] = @tag_group.errors.full_messages
          render :action => 'new'
      end
    rescue => e
        log("Add","GroupTag",false,"#{e.message}")
        flash[:error] = "Add group tag has been failed.[#{e.message}]"
        redirect_to :controller => 'call_tags', :action => 'index'
    end

  end

  def edit

    begin
#      @tag_group = TagGroup.find(params[:id])
      @tag_group = TagGroup.where(:id => params[:id]).first
    rescue => e
      log("Edit","GroupTag",false,"#{e.message}")
      redirect_to :controller => 'call_tags', :action => 'index'
    end
    
  end

  def update

    begin
      @tag_group = TagGroup.find(params[:id])

      if @tag_group.update_attributes(params[:tag_group])
          log("Update","GroupTag",true,"id:#{params[:id]}, name:#{@tag_group.name}")
          redirect_to :controller => 'call_tags', :action => 'index',:group_id => params[:id]
      else
          log("Update","GroupTag",false,"id:#{params[:id]}, #{@tag_group.errors.full_messages}")
          flash[:message] = @tag_group.errors.full_messages
          render :action => 'edit'
      end

    rescue => e
      log("Update","GroupTag",false,"id:#{params[:id]},#{e.message}")
      flash[:error] = "Update group tag has been failed.[#{e.message}]"
      redirect_to :controller => 'call_tags', :action => 'index',:group_id => params[:id]
    end
    
  end

  def delete

    begin
      tag_group = TagGroup.find(params[:id])

      #if can_delete?(tag_group.id)
        log("Delete","GroupTag",true,"id:#{params[:id]}, name:#{tag_group.name}")
        tag_group.destroy
        redirect_to :controller => 'call_tags', :action => 'delete_all_by_group_id', :gid => params[:id]
        #tags = Tag.find(:all,:conditions => {:tag_group_id => params[:id]})
        #unless tags.blank?
        #  tags_id = tags.map { |t| t.id }
        #  log("Delete","CallTags",true,"id:#{tags_id.join(',')}")
        #  Tag.delete_all("tag_group_id in (#{params[:id]})")
        #  Taggings.delete_all("tag_id in (#{tags_id.join(',')})")
        #end
      #else
      #  log("Delete","GroupTag",false,"id:#{params[:id]}, delete was cancelled.")    
      #end
    rescue => e
      log("Delete","GroupTag",false,"id:#{params[:id]}, #{e.message}")
      flash[:error] = "Delete group tag has been failed.[#{e.message}]"
    end

    redirect_to :controller => 'call_tags', :action => 'index'

  end

  def can_delete?(gt_id)

    can_delete = false
    tags = Tag.find(:all,:conditions => {:tag_group_id => gt_id})
    unless tags.blank?
      tags_id = tags.map { |t| t.id }
      tags_list = Taggings.find(:all,:conditions => "tag_id in (#{tags_id.join(',')})")
      if tags_list.empty?
        can_delete = true  
      end
    else
      can_delete = true
    end

    return can_delete

  end
  
end
