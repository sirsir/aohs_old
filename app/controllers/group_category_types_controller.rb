class GroupCategoryTypesController < ApplicationController

  layout "control_panel"

  before_filter :login_required,:permission_require

   def index

      redirect_to :controller => 'group_category',:action => 'index'

   end

   def new

      @group_category_type = GroupCategoryType.new

   end

   def edit
     
     begin
       @group_category_type = GroupCategoryType.where(:id => params[:id]).first
     rescue
       redirect_to :controller => 'group_category',:action => 'index'
     end

   end

   def create

     @group_category_type = GroupCategoryType.new(params[:group_category_type])

     if @group_category_type.save

         max_id = GroupCategoryType.maximum(:order_id)
         if max_id.nil?
           max_id = 0
         else
           max_id = max_id.to_i
         end
         @group_category_type.update_attributes({:order_id => (max_id + 1)})
         
         #update category display tree
         gct_id = GroupCategoryType.where(:name => @group_category_type.name).first
         gcdt = GroupCategoryDisplayTree.select('max(id) as id').first
         if gcdt.nil?
            GroupCategoryDisplayTree.new(:group_category_type => gct_id,:parent_id => nil).save!
         else
            GroupCategoryDisplayTree.new(:group_category_type => gct_id,:parent_id => gcdt.id).save!
         end

         log("Add","CategoryType",true,"id:#{@group_category_type.id}, name:#{@group_category_type.name}")

         redirect_to :controller => 'group_category', :action => 'index'
     else
        log("Add","CategoryType",false)
        flash[:message] = 'Please check you category type\'s name.'
        render :action => 'new'
     end

   end

   def update

      @group_category_type = GroupCategoryType.where(:id => params[:id]).first

     if @group_category_type.update_attributes(params[:group_category_type])
          log("Update","CategoryType",true,"id:#{params[:id]}, name:#{@group_category_type.name}")
          flash[:notice] = 'Update category type was successfully.'

          redirect_to :controller => 'group_category', :action => 'index'
      else
          log("Update","CategoryType",false,"id:#{params[:id]}, name:#{@group_category_type.name}")
          flash[:message] = 'Edit category type information failed. Please try again.'

          render :action => 'edit'
      end

   end
   def delete
       destroy
   end
  
   def destroy

        @group_category_type = GroupCategoryType.where(:id => params[:id]).first

        gct_id = @group_category_type.id

        if can_delete(gct_id)
          
          gcdts = GroupCategoryDisplayTree.all
          cate_type = []
          if !gcdts.nil?
          gcdts.each { |x| cate_type << {:id => x.id, :name => x.group_category_type.name, :parent_id => x.parent_id } if not x.parent_id }
          gcdts.length.times {
            f = cate_type.last
            gcdts.each { |x| cate_type << {:id => x.id, :name => x.group_category_type.name, :parent_id => x.parent_id } if x.parent_id and x.parent_id.to_i == f[:id].to_i }
          }
          end
          # reset display tree
          parent_id = nil

          gctdp = GroupCategoryDisplayTree.joins(:group_category_type)
          gctdp = gctdp.where("group_category_types.name like '#{@group_category_type.name}'")
          gctdp = gctdp.first
          unless gctdp.nil?
            gctdp.destroy
          end
          
          cate_type.each do |x|
            if not x[:name] == @group_category_type.name
              gcdt = GroupCategoryDisplayTree.joins(:group_category_type)
              gcdt = gcdt.where("group_category_types.name like '#{x[:name]}'")
              gcdt = gcdt.first
              GroupCategoryDisplayTree.update(gcdt.id,{:parent_id => parent_id })
              parent_id = gcdt.id
            end
          end
          
          if @group_category_type.destroy
             gc = GroupCategory.where(:group_category_type_id => gct_id)
             if not gc.empty?
               GroupCategory.delete_all(:group_category_type_id => gct_id)

               gc_ids = []
               gc.each { |x| gc_ids << x.id }

               grp = GroupCategorization.where("group_category_id in (#{gc_ids.join(',')})")
               if not grp.empty?
                 GroupCategorization.delete_all("group_category_id in (#{gc_ids.join(',')})")
               end

               log("Delete","CategoryType",true,"id:#{params[:id]}")
               flash[:notice] = 'Delete category type was successfully.'
             end
          else
            log("Delete","CategoryType",false,"id:#{params[:id]}")
            flash[:error] = 'Delete category type was failed.'
          end
        else
            log("Delete","CategoryType",false,"id:#{params[:id]}, delete was cancelled.")
            flash[:error] = 'Delete category type was failed because is using'
        end

        redirect_to :controller => 'group_category', :action => 'index'
   end

   def can_delete(id)

     gc = GroupCategory.where(:group_category_type_id => id)

     if not gc.empty?
       gc_ids = []
       gc.each { |x| gc_ids << x.id }

       grp = GroupCategorization.where("group_category_id in (#{gc_ids.join(',')})")
       
       # problem! now not check delete group conditions

       if grp.empty?
         return true
       else
         return false
       end
     else
       return true
     end

   end
   
 end
