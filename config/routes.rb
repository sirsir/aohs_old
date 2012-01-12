ActionController::Routing::Routes.draw do |map|

  map.connect 'users/update_extension',:controller => 'users',:action => 'update_extension'

  map.resources :users
  map.resources :accounts
  map.resource :session

  map.index  "/", :controller => "top_panel", :action => "index"

  map.signup "/activate", :controller => "accounts", :action => "activate"
  map.signup "/signup", :controller => "accounts", :action => "new"
  map.login  "/login",  :controller => "sessions", :action => "new"
  map.logout "/logout", :controller => "sessions", :action => "destroy"

  map.connect '/keywords.txt', :controller => 'keywords', :action => 'keywords'
  
  map.connect 'groups/tree_json', :controller => 'groups', :action => 'tree_json'
  map.connect 'groups/list_agents', :controller => 'groups', :action => 'list_agents'

  map.connect 'statistics', :controller => 'statistics', :action => 'index'
  map.connect 'statistics/agent', :controller => 'statistics', :action => 'agent'
  map.connect 'statistics/export_agent', :controller => 'statistics', :action => 'export_agent' 
  map.connect 'statistics/print_agent', :controller => 'statistics', :action => 'print_agent'     
  map.connect 'statistics/:period/export', :controller => 'statistics',:action=> 'export'
  map.connect 'statistics/:period/print', :controller => 'statistics',:action=> 'print'  
  map.connect 'statistics/:period', :controller => 'statistics', :action => 'index'
  
  map.connect 'top_panel', :controller => 'top_panel', :action => 'index'

  map.connect 'event', :controller => 'event', :action => 'index'

  map.connect 'log', :controller => 'log', :action => 'index'

  map.connect 'permission', :controller => 'permission', :action => 'index' 

  map.group_category 'group_category/:action/:id', :controller => 'group_categories'
  map.group_categories 'group_category/:action/:id', :controller => 'group_categories'
  map.group_category_types 'group_category_type', :controller => 'group_categories', :action=>"index"
  map.group_category_types 'group_category_type/:action/:id', :controller => 'group_category_types'

  map.connect 'keywords/autocomplete_list', :controller => 'keywords', :action => 'autocomplete_list'  
  map.connect 'keywords/keywords_agents', :controller => 'keywords',:action => 'keywords_agents'
  map.connect 'keywords/export', :controller => 'keywords',:action=> 'export'
  map.connect 'keywords/print', :controller => 'keywords',:action=> 'print'
  map.connect 'keywords/print_agent', :controller => 'keywords',:action=> 'print_agent'
  map.connect 'keywords/export_agent', :controller => 'keywords',:action=> 'export_agent'
  map.connect 'keywords/result_keywords', :controller => 'keywords',:action=> 'result_keywords'
  map.connect 'keywords/keywords.txt', :controller => 'keywords',:action=> 'keywords'
  map.connect '/keyword_group',:controller => 'keyword_group',:action => 'index'

  map.connect 'call_browser', :controller => 'call_browser', :action => 'index'
  map.connect 'call_browser/get_info', :controller => 'call_browser', :action => 'get_info'

  map.connect 'voice_logs/search_voice_log', :controller => 'voice_logs', :action => 'search_voice_log'
  map.connect 'voice_logs/export', :controller => 'voice_logs', :action => 'export'
  map.connect 'voice_logs/timeline_source',:controller=>'voice_logs',:action=>'timeline_source'
  map.connect 'voice_logs/print',:controller=>'voice_logs',:action=>'print'
  map.connect 'voice_logs/download',:controller=>'voice_logs',:action=>'download'
  map.connect 'voice_logs/:period',:controller => 'voice_logs', :action => 'index', :period => /(today)|(yesterday)|(day_ago)|(this_week)|(this_month)|(daily)|(weekly)|(monthly)/
  
  map.connect 'agents/userlist', :controller => 'agents', :action => 'userlist'
 
  map.connect 'agents/list.:format', :controller => 'agents', :action => 'list'
  map.connect 'voice_logs/list.:format', :controller => 'voice_logs', :action => 'list'

  map.connect 'configurations/get_config', :controller => 'configurations', :action => 'get_config'
  map.connect 'configurations/update_config', :controller => 'configurations', :action => 'update_config'
  map.connect 'configurations.txt', :controller => 'configurations', :action => 'export'
  
  map.connect 'favorites/tag_print',:controller=> 'favorites', :action => 'tag_print'
  map.connect 'users/change_password',:controller=>'users',:action => 'change_password'
  map.resources :keywords
  map.resources :voice_logs
  map.resources :configurations
  map.resources :agents
  map.resources :managers
  map.resources :groups
  map.resources :group_categories
  map.resources :group_category_types
 # map.resources :extension

# [TODO] administration pages move to "admin" namespace
#   map.namespace(:admin) do |admin|
#      admin.root :controller => 'control_panel', :action => 'index'
#      admin.connect 'event', :controller => 'event', :action => 'index'
#   end

#   map.connect 'agents/:action/:id', :controller => 'users', :type => 'Agent'
#   map.connect 'managers/:action/:id', :controller => 'users', :type => 'Manager'
#   map.agent 'agents/:action/:id', :controller => 'agent'
#   map.manager 'managers/:action/:id', :controller => 'manager'

#   map.connect 'voice_logs/today', :controller => 'voice_logs', :action => 'index', :d => "#{Date.today.strftime('%Y%m%d')}"
#   map.connect 'voice_logs/yesterday', :controller => 'voice_logs', :action => 'index', :d => "#{(Date.today-1).strftime('%Y%m%d')}"
#   map.connect 'voice_logs/days_ago', :controller => 'voice_logs', :action => 'index', :d => "#{(Date.today-3).strftime('%Y%m%d')}"

# [TODO] きれいな保存用URLの作成
# 以下のようなURLをブックマークしておくことで誰かとシェアしたい情報を保存しておくことができる
#   http://localhost:3000/calls/2008/12/12/yamamoto
#   http://localhost:3000/calls/2008/12/12/yamamoto?cs=AEONTHAI
# ただし、このURLからフォームで検索するとURLがついてまわるのでおかしなことになる。
# このルーティングでは、追加で検索できないようなページにしておく必要あり。
   map.connect 'calls/:year', :controller => 'voice_logs', :action => 'index'
   map.connect 'calls/:year/:month', :controller => 'voice_logs', :action => 'index'
   map.connect 'calls/:year/:month/:day', :controller => 'voice_logs', :action => 'index'
   map.connect 'calls/:year/:month/:day/:agent', :controller => 'voice_logs', :action => 'index'

   # The priority is based upon order of creation: first created -> highest priority.

   # Sample of regular route:
   #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
   # Keep in mind you can assign values other than :controller and :action

   # Sample of named route:
   #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
   # This route can be invoked with purchase_url(:id => product.id)

   # Sample resource route (maps HTTP verbs to controller actions automatically):
   #   map.resources :products

   # Sample resource route with options:
   #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

   # Sample resource route with sub-resources:
   #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

   # Sample resource route with more complex sub-resources
   #   map.resources :products do |products|
   #     products.resources :comments
   #     products.resources :sales, :collection => { :recent => :get }
   #   end

   # Sample resource route within a namespace:
   #   map.namespace :admin do |admin|
   #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
   #     admin.resources :products
   #   end

   # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
   # map.root :controller => "welcome"

   # See how all your routes lay out with "rake routes"

   # Install the default routes as the lowest priority.
   # Note: These default routes make all actions in every controller accessible via GET requests. You should
   # consider removing the them or commenting them out if you're using named routes and resources.
   map.connect ':controller/:action/:id'
   map.connect ':controller/:action/:id.:format'

end
