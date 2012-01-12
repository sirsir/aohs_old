class ControlPanelController < ApplicationController
 
   layout "control_panel"
   
   before_filter :login_required,:permission_require

   def index

    @ctrl_menus = [
      {:name => "Managers", :url => {:controller => 'managers',:action => 'index'}, :title => "", :image => "manager.png"},
      {:name => "Agents", :url => {:controller => 'agents',:action => 'index'}, :title => "", :image => "agent.png"},
      {:name => "Groups", :url => {:controller => 'groups',:action => 'index'}, :title => "", :image => "group_2.png"},
      {:name => "Category", :url => {:controller => 'group_categories',:action => 'index'}, :title => "", :image => "category.png"},
      {:name => "Calls Tags", :url => {:controller => 'call_tags',:action => 'index'}, :title => "", :image => "calltag.png" },
	    {:name => "Extensions", :url => {:controller => 'extension',:action => 'index'}, :title => "", :image => "extension.png" },
	    {:name => "Customers", :url => {:controller => 'customer',:action => 'index'}, :title => "", :image => "customer.png" },
      {:name => "Logs", :url => {:controller => 'log',:action => 'index'}, :title => "", :image => "log.png"},
      {:name => "Computer Log", :url => {:controller => 'computer_log',:action => 'index'}, :title => "", :image => "computer.png"},
     # {:name => "Event", :url => {:controller => 'event',:action => 'index'}, :title => "", :image => "event.png"},
      {:name => "Permissions", :url => {:controller => 'permission',:action => 'index'}, :title => "", :image => "permission.png"},
      {:name => "Server and Client configurations", :url => {:controller => 'configurations',:action => 'index'}, :title => "", :image => "setting.png"}
    ].reverse
   
    new_menus = []
    @ctrl_menus.each do |o|
      u = o[:url]
      if link_permission_require(u[:controller],u[:action])
        new_menus << o  
      end
    end
    @ctrl_menus = new_menus
   end

end
