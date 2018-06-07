Rails.application.routes.draw do
  
  get 'system_info/index'

  devise_for :users

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#index'

  get 'configurations.:format'  => 'configurations#configurations'
  
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'
  
  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase
  
  # Example resource route (maps HTTP verbs to controller actions automatically):
  
  resources :analytics, only: :index do
    collection do
      get   'word_cloud'
      get   'classification'
      get   'reason'
      get   'assessment'
      get   'wordcloud'
      get   'dasb_call_class'
    end
  end
  
  resources :analytic_templates do
    
  end
  
  resources :assignments, only: :index do
    collection do
      get   'query'
    end
  end
  
  resources :auto_assessment_rules do
    
  end
  
  resources :call_browser do
    collection do
      get   'members'
      get   'summary_data'
      get   'get_voice_log'
      post  'call_status'
    end
  end
  
  resources :call_histories do
    collection do
      post  'list'
    end
  end
  
  resources :call_evaluation, only: [:index] do
    collection do
      get    'check_agent_info'
    end
  end
  
  resources :call_categories do
    collection do
      get   'list'
      get   'types'
      post  'update_types'
    end
  end
  
  resources :computer_logs
  
  resources :content_style, only: [:index] do
    collection do
      get   'content_style'
    end
  end
  
  resources :configurations do
    collection do
      post  'update_programs'
      get   'update_program_list'
      get   'update_module'
      post  'update_locations'
      post  'update_display_columns'
    end
  end
  
  resources :customers

  resources :custom_dictionaries

  resources :document_templates do
    member do
      get   'download_preview'
    end
  end

  resources :evaluation_plans do
    member do
      get   'group_and_questions'
    end
    collection do
      get   'list'
    end
    resources :evaluation_criteria do
      collection do
        get   'list'
      end
    end
  end
  
  resources :evaluation_tasks do
    member do
      get  'change_task_status'
    end
    collection do
      get  'assignment'
      get  'unassignment'
      get  'assignment_info'
      post 'query'
      post 'query_assigned'
      post 'change_assignee'
    end
  end

  resources :evaluation_questions do
    collection do
      get  'create_group'
      get  'group_options'
      get  'update_group'
      get  'delete_group'
    end
  end
  
  resources :evaluation_grade_settings do
    
  end
  
  resources :export_calls do
    
  end

  resources :export_calls, as: "export_tasks" do
    
  end
  
  resources :errors, only: :index do
    collection do
      get   'denied'
      get   'no_content'
    end
  end
  
  resources :file_upload do
    collection do
      post  'upload'
    end
  end

  resources :faq_questions do

  end
  
  resources :groups do
    member do
      get   'info'
    end
    collection do
      get   'list'
    end
  end
  
  resources :group_members do
    collection do
      get   'update_member'
    end
  end
  
  resources :home, only: :index do
    collection do
      get   'portal'
      get   'nodas'
      get   'qa'
    end
  end
  
  resources :dashboard, only: :index do
    collection do
      get   'agent_monitor'
      get   'qa_manager'
      get   'tv_data'
      get   'das_data'
      get   'das_timeline'
    end
  end
  scope :aeoncol do
    resources :dashboard
  end
  
  resources :keywords do
    member do
      get   'keyword_type'
    end
    collection do
      get   'list'
      get   'keywords'
      get   'settings'
    end
  end
  
  resources :keyword_types do
      
  end
  
  resources :maintenances do
    collection do
      get   'call_activity'
      get   'watcher_status'
    end
  end

  resources :manual, only: :index do
    
  end
  
  resources :operation_logs, only: :index
  
  resources :permissions do
    collection do
      get   'update_permission'
    end
  end
  
  resources :phone_extensions, as: 'extensions' do
    collection do
      get   'export'
      get   'import'
      get   'watcher'
    end
  end
  
  resources :phone_infos, as: 'phone_infos' do
    
  end
  
  resources :reports do
    collection do
      get   'agent_keyword_summary'
      get   'call_overview'
      get   'call_summary'
      get   'agent_call_usage'
      get   'hourly_call_summary'
      get   'agent_call_summary'
      get   'group_call_summary'
      get   'call_tags'

      get   'top_repeated_inbound'
      get   'top_repeated_outbound'
      get   'private_call_summary'
       
      # keyword
      get   'keyword_notification_summary'
      
      # notification
      get   'notif_rec_summary'
      get   'notif_keyword_summary'
      
      # other
      get   'monitoring_usage'
    end
  end
  
  resources :evaluation_reports, only: :index do
    collection do
      get   'agent_detail'
      get   'agent_summary'
      get   'group_summary'
      get   'evaluator_summary'
      get   'evaluator_call_summary'
      get   'attachment_list'
      get   'check_summary'
      get   'check_detail'
      get   'asst_details'
      # qms ->
      get   'acs_greeting'
      get   'acs_agent_call_summary'
      get   'acs_ngusage_summary'
      get   'acs_call_summary'
      get   'acs_evaluation_summary'
      # -> qms
    end
  end
  
  resources :evaluation_doc_attachments do
    member do
      get    'doc_delete'
    end
    collection do
      get    'list'
      get    'download'
      get    'not_found'
    end
  end
  
  resources :message_logs do
    collection do
      get   'download'
    end
  end
  
  resources :roles

  resources :search, only: [:index] do
  
  end

  resources :tags do
    collection do
      get   'autocomplete'
      get   'tag_style'
      get   'list'
    end
  end
  
  resources :test, only: [:index] do
    
  end
  
  resources :users do
    
    member do
      get   'profile'
      post  'password'
      post  'undelete'
      get   'update_attr'
      get   'get_attr'
      get   'get_group'
      get   'avatar'
      post  'upload_image'
      get   'unlock'
      get   'card'
      get   'notify'
    end
    
    collection do
      get   'export'
      get   'import'      
      get   'logout'
      get   'list'
      get   'mailer'
      get   'unlock_info'
    end
    
    resources :user_educations do
      member do
        post  'delete'
      end
      collection do
        get   'list'
      end
    end

    resources :user_experiences do
      member do
        post  'delete'
      end
      collection do
        get   'list'
      end
    end
    
  end

  resources :voice_logs, only: [:index] do
    member do
      get   'waveform'
      get   'call_events'
      get   'call_type'
      get   'call_tagging'
      get   'keyword_log'
      get   'dsrresult_log'
      get   'trans_log'
      get   'trans_file'
      get   'download'
      get   'fav_call'
      post  'update_transcription'
      #get   'check_result'
      get   'evaluated_score'
      get   'evaluated_info'
      get   'remove_evaluation'
      post  'evaluate'
      get   'evaluation_more_info'
      get   'assessment_info'
      get   'ana_result_logs'
      #get   'recalc_score'
      get   'info'
    end
    collection do
      get   'tagging'
      get   'export'
      get   'stream_url'
      post  'send_mail'
    end
    
    resources :call_comments do
      collection do
        post  'update_comment'
        post  'delete_comment'
        get   'list'
      end
    end
    
    resources :call_tags do
      collection do
        post  'update_tags'
        get   'list'
      end
    end
    
  end
  
  resources :watchercli, only: [:index] do 
    member do
      get 'notification'
      get 'notification_history'
    end

    collection do 
      get 'log/:message_id/:reference_id' => :log
    end
  end

  resources :webapi, only: [:index] do
    collection do
      get   'users'
      post  'update_computer_log'
      #get   'update_computer_log'
      post  'update_computer_logs'
      post  'agent_activity'
      match 'agent_lookup', via: [:get, :post]
      get   'checker'
      get   'dictionary'
      get   'assessment_rules'
      get   'faq_questions'
      post  'client_notify'
      get   'client_notify'
    end
  end
  
  resources :web_sessions, only: [:index] do
    
  end
  
  resources :web_tracking_log do
    collection do
      get   'call_logging'
    end
  end

  resources :system_info, only: [:index] do
    collection do
      get   'app_info'
      get   'tables'
      get   'schedule'
      get   'check'
      get   'tools'
    end
  end
   
  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

end
