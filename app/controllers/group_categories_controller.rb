class GroupCategoriesController < ApplicationController

   layout "control_panel"

   before_filter :login_required,:permission_require
   
   def index

      conditions = {}
      if params.has_key?(:tabc) and not params[:tabc].empty?
        conditions[:id] = params[:tabc] if params[:tabc].to_i > 0
      end
      
      @group_category_types = GroupCategoryType.includes("categories").where(conditions).order('order_id asc')
      @group_category_types_all = GroupCategoryType.order('order_id asc')
     
   end

   def new

      category_type = GroupCategoryType.all

      category_type.each do |x|
        if x.name == params[:type_name]
          @category_type = x.id
          break
        end
      end

      unless category_type.nil?
        @group_category = GroupCategory.new
      else
        flash[:notice] = "Category type cannot found. Please create category type before create category."
        redirect_to :controller => 'group_category_types',:action => 'new'
      end

   end
   
   def create
     
      @group_category = GroupCategory.new(params[:group_category])

      if @group_category.save
        log("Add","GroupCategory",true,"id:#{@group_category.id}, name:#{@group_category.value}")
        flash[:notice] = 'Create category has been successfully.'

        redirect_to :controller => 'group_category',:action => 'index', :tabc => @group_category.group_category_type_id
      else
        log("Add","GroupCategory",false)
        flash[:message] = "Create category failed. Please try again."

        render :controller => 'group_category',:action => 'new'
      end
      
   end

   def edit

      begin
        
        @group_category = GroupCategory.find(params[:id])
      
      rescue => e
        
        log("Edit","GroupCategory",false,"id:#{params[:id]},#{e.message}")
        flash[:error] = 'Update category have some problems. Please try again.'
        redirect_to :controller => 'group_category',:action => 'index'

      end

   end

   def update

      begin
        @group_category = GroupCategory.find(params[:id])

        if @group_category.update_attributes(params[:group_category])
            log("Update","GroupCategory",true,"id:#{params[:id]}, name:#{@group_category.value}")
            flash[:notice] = 'Update category was successfully.'

            redirect_to :controller => 'group_category',:action => 'index', :tabc => @group_category.group_category_type_id
        else
            log("Update","GroupCategory",false,"id:#{params[:id]}, #{@group_category.errors.full_messages}")
            flash[:message] = @group_category.errors.full_messages

            render :controller => 'group_category',:action => 'edit'
        end
        
      rescue => e
        log("Update","GroupCategory",false,"id:#{params[:id]},#{e.message}")
        flash[:error] = 'Update category have some problems. Please try again.'
        redirect_to :controller => 'group_category',:action => 'index'
        
      end


   end

   def delete

     begin

        @group_category = GroupCategory.find(params[:id])

        if can_delete(@group_category.id)
          if @group_category.destroy
            log("Delete","GroupCategory",true,"id:#{params[:id]}, name:#{@group_category.value}")
            flash[:notice] = 'Delete category was successfully.'
          else
            log("Update","GroupCategory",false,"id:#{params[:id]}, name:#{@group_category.value}")
            flash[:error] = 'Delete category was failed.'
          end
        else
          log("Update","GroupCategory",false,"id:#{params[:id]}, name:#{@group_category.value}, delete was cancelled.")
          flash[:error] = 'Delete category was failed because this category is using.'
        end

        redirect_to :controller => 'group_category',:action => 'index'

     rescue => e
       
        log("Update","GroupCategory",false,"id:#{params[:id]}, #{e.message}")
        flash[:error] = 'Update category have some problems. Please try again.'
        redirect_to :controller => 'group_category',:action => 'index'
        
     end

   end

   def can_delete(id)

     gcate = GroupCategorization.where({:group_category_id => id}).all

     if gcate.empty?
       return true
     else
       return false
     end

   end

   def display_tree

     gcdts = GroupCategoryDisplayTree.all
     n = 0
     cate_type = []
     if !gcdts.empty?
     gcdts.each { |x| 
       if (x.parent_id).nil?
        cate_type << {:id => x.id, :name => x.group_category_type.name, :parent_id => x.parent_id }
       end
     }
    gcdts.length.times {
        f = cate_type.last
        gcdts.each { |x|          
          if !(x.parent_id).nil? and !f.nil?
            if (x.parent_id).to_i == f[:id].to_i
              cate_type << {:id => x.id, :name => x.group_category_type.name, :parent_id => x.parent_id }
            end
          end
        }
     }
    end

     @cate_type = ""
     cate_type.map { |x| @cate_type << "<option value=\"#{x[:id]}\">#{x[:name]}</option>" }
     
   end

   def update_display_tree
   
     if params.has_key?('cate_type') and not params[:cate_type].empty?

       tmp_ary = params[:cate_type].split(',')
       order_list = []
       tmp_ary.each { |x| order_list << {:no => x.split('=')[0], :name => x.split('=')[1]} }

       parent_id = nil
       order_list.each_with_index do |x,i|
         gcdt = GroupCategoryDisplayTree.includes('group_category_type').where("group_category_types.name like '#{x[:name]}'").first
         GroupCategoryDisplayTree.update(gcdt.id,{:parent_id => parent_id })
         parent_id = gcdt.id
         
         GroupCategoryType.update(gcdt.group_category_type,{:order_id => i})
       end

     end

     log("Update","AgentTreeView",true,"list:#{params[:cate_type]}")
     
     flash[:notice] = "Save change was successfully."
     
     redirect_to :controller => 'group_categories',:action => 'display_tree'
     
   end

   def reset_display_tree

    GroupCategoryDisplayTree.delete_all
    
    gcts = GroupCategoryType.order('order_id asc')

    tree_list = []
    gcts_id = []
    gcts.each do |gct|
      gcts_id << gct
      tree_list << gct.name
    end

    parent_id = nil
    gcts_id.each do |gct|
      GroupCategoryDisplayTree.new({:group_category_type => gct,:parent_id => parent_id }).save!
      gcdt_id = GroupCategoryDisplayTree.where({:group_category_type => gct}).first.id
      parent_id = gcdt_id
    end

    log("Update","AgentTreeView",true,"reset tree, list:#{tree_list.join(',')}")

    render :layout => false, :text => 'true'

  end
  
end