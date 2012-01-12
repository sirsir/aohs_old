class KeywordGroupController < ApplicationController

  before_filter :login_required
  
  def index

      @keyword_group = KeywordGroup.paginate(:page => params[:page],:per_page => $PER_PAGE)

  end

  def edit

      begin
        @keyword_group = KeywordGroup.find(params[:id])
      rescue => e
        log("Edit","KeywordGroup",false,"id:#{params[:id]}")
        redirect_to :controller => 'keywordd_group',:action => 'index'
      end
    
  end

  def show
  
      @keyword_group = KeywordGroup.find(params[:id])

  end

  def update

    begin
      @keyword_group = KeywordGroup.find(params[:id])
      if @keyword_group.update_attributes(params[:keyword_group]) and not @keyword_group.name.blank?
        log("Update","KeywordGroup",true,"id:#{params[:id]}")
        redirect_to :action => 'show',:id => @keyword_group.id
      else
        log("Update","KeywordGroup",false,"id:#{params[:id]},#{@keyword_group.errors.full_messages}")
        flash[:message] = @keyword_group.errors.full_messages
        redirect_to :action => 'edit',:id => @keyword_group.id
      end
    rescue => e
      log("update","KeywordGroup",false,"id:#{params[:id]},#{e.message}")
      redirect_to :action => 'edit',:id => @keyword_group.id
    end
      
  end

  def new
     @keyword_group = KeywordGroup.new
  end

  def create

    begin
      @keyword_group = KeywordGroup.new(params[:keyword_group])
      if @keyword_group.save
        log("Add","KeywordGroup",true,"name:#{@keyword_group.name}")
        redirect_to :controller => 'keyword_group',:action => 'index'
      else
        log("Add","KeywordGroup",false,"id:#{params[:id]},#{@keyword_group.errors.full_messages}")
        flash[:message] = @keyword_group.errors.full_messages
        render :action => 'new'
      end
    rescue => e
       log("Add","KeywordGroup",false,"id:#{params[:id]},#{e.message}")
       render :action => 'new'
    end

  end

  def delete

    begin
      @keyword_group = KeywordGroup.find(params[:id])
      kgname = @keyword_group.name

      if in_used?(@keyword_group.id)
        if @keyword_group.destroy
          rs = KeywordGroupMap.delete_all(:keyword_group_id => params[:id])
          log("Delete","KeywordGroup",true,"id#{params[:id]},name:#{kgname}")
        else
          log("Delete","KeywordGroup",false,"id#{params[:id]},name:#{kgname}")
          flash[:error] = 'Delete Keyword group failed.'
        end
      else
         log("Delete","KeywordGroup",false,"id#{params[:id]},name:#{kgname}")
         flash[:error] = "Can't delete keyword group. now keyword group in used."
      end
    rescue => e
      log("Delete","KeywordGroup",false,"id#{params[:id]},#{e.message}")
    end
    
    redirect_to :action => 'index'

  end

  def in_used?(kgid)

     KeywordGroupMap.exists?({:keyword_group_id => kgid})

  end
  
end
