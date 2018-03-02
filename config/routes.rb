AohsWeb::Application.routes.draw do
  
  match 'users/update_extension' => 'users#update_extension'
  match 'users/update_agent_activity' => 'users#update_agent_activity'
  match 'users/change_password' => 'users#change_password'  
  
  resources :users
  resources :accounts
  resource :session
  
  match '/activate' => 'accounts#activate', :as => :signup
  match '/signup' => 'accounts#new', :as => :signup
  match '/login' => 'sessions#new', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout 
  
  match '/admin' => 'sessions#new', :as => :admin
  
  match 'keywords.txt' => 'keywords#keywords'
  match 'configurations.txt' => 'configurations#export'  
  
  match 'groups/tree_json' => 'groups#tree_json'
  match 'groups/list_agents' => 'groups#list_agents'

  match 'statistics' => 'statistics#index'  
  match 'statistics/agent' => 'statistics#agent'
  match 'statistics/export_agent' => 'statistics#export_agent'
  match 'statistics/print_agent' => 'statistics#print_agent'
  match 'statistics/:period/export' => 'statistics#export', :period => /(monthly)|(weekly)|(daily)/
  match 'statistics/:period/print' => 'statistics#print', :period => /(monthly)|(weekly)|(daily)/
  match 'statistics/:period' => 'statistics#index', :period => /(monthly)|(weekly)|(daily)/
  
  match 'top_panel' => 'top_panel#index'
  
  match 'event' => 'event#index'
  
  match 'log' => 'log#index'
  
  match 'permission' => 'permission#index'
  
  match 'group_category' => 'group_categories#index', :as => :group_category
  match 'group_category' => 'group_categories#index', :as => :group_categories
  match 'group_category/delete/:id' => 'group_categories#delete', :as => :group_category
  match 'group_category/delete/:id' => 'group_categories#delete', :as => :group_categories  
  match 'group_category/edit/:id' => 'group_categories#edit', :as => :group_category
  match 'group_category/edit/:id' => 'group_categories#edit', :as => :group_categories
  match 'group_category/update/:id' => 'group_categories#update', :as => :group_category
  match 'group_category/update/:id' => 'group_categories#update', :as => :group_categories      
  match 'group_category_type' => 'group_categories#index', :as => :group_category_types
  match 'group_category_type/:action/:id' => 'group_category_types#index', :as => :group_category_types
  match 'group_categories/display_tree' => 'group_categories#display_tree', :as => :group_categories
  match 'group_categories/update_display_tree' => 'group_categories#update_display_tree', :as => :group_categories
  match 'group_category/update_display_tree' => 'group_categories#update_display_tree', :as => :group_category
  
  match 'keywords/autocomplete_list' => 'keywords#autocomplete_list'
  match 'keywords/keywords_agents' => 'keywords#keywords_agents'
  match 'keywords/export' => 'keywords#export'
  match 'keywords/print' => 'keywords#print'
  match 'keywords/print_agent' => 'keywords#print_agent'
  match 'keywords/export_agent' => 'keywords#export_agent'
  match 'keywords/result_keywords' => 'keywords#result_keywords'
  match 'keywords/get_edit_keywords' => 'keywords#get_edit_keywords'
  match 'keywords/keywords.txt' => 'keywords#keywords'
  match 'keyword_group' => 'keyword_group#index'

  match 'call_browser' => 'call_browser#index'
  match 'call_browser/get_info' => 'call_browser#get_info'
  
  match 'voice_logs/search_voice_log' => 'voice_logs#search_voice_log'
  match 'voice_logs/export' => 'voice_logs#export'
  match 'voice_logs/timeline_source' => 'voice_logs#timeline_source'
  match 'voice_logs/print' => 'voice_logs#print'
  match 'voice_logs/download' => 'voice_logs#download'
  match 'voice_logs/get_transfer_calls' => 'voice_logs#get_transfer_calls'
  match 'voice_logs/get_transfer_list' => 'voice_logs#get_transfer_list'
  match 'voice_logs/get_call_info' => 'voice_logs#get_call_info'
  match 'voice_logs/:period' => 'voice_logs#index', :period => /(today)|(yesterday)|(day_ago)|(this_week)|(this_month)|(daily)|(weekly)|(monthly)/
  match 'voice_logs/file/:id.:format' => 'voice_logs#file'
  match 'voice_logs/viewer' => 'voice_logs#viewer'
  match 'voice_logs/download_file/:id' => 'voice_logs#download_file'
  match 'agents/userlist' => 'agents#userlist'
  match 'agents/list.:format' => 'agents#list'
  match 'voice_logs/list.:format' => 'voice_logs#list'
  match 'configurations/get_config' => 'configurations#get_config'
  match 'configurations/update_config' => 'configurations#update_config'
  
  match 'favorites/tag_print' => 'favorites#tag_print'

  resources :keywords
  resources :voice_logs
  resources :configurations
  resources :agents
  resources :managers
  resources :groups
  resources :group_categories
  resources :group_category_types
  
  match 'call_browser' => 'call_browser#index'
  
  match 'calls/:year' => 'voice_logs#index'
  match 'calls/:year/:month' => 'voice_logs#index'
  match 'calls/:year/:month/:day' => 'voice_logs#index'
  match 'calls/:year/:month/:day/:agent' => 'voice_logs#index'

  match '/:controller(/:action(/:id))'
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"
  root :to => "top_panel#index"
  
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
