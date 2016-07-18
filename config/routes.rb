Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'
  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  root 'index#index'

  resources :teams

  resources :invitations do
    get 'accept', on: :member
    get 'reject', on: :member
    get :autocomplete_user_nickname, on: :collection
  end

  # resources :game_passings do
  #   get 'show_results', on: :member
  # end

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

  resources :users do
    resources :games
  end

  resources :games do
    resources :levels do
      resources :hints
      resources :questions do
        resources :answers
        get 'move_up', on: :member
        get 'move_down', on: :member
      end

      get 'move_up', on: :member
      get 'move_down', on: :member
    end
    get 'show_scenario', on: :member
  end

  get 'game_entries/recall/:id' => 'game_entries#recall'
  get 'game_entries/reopen/:id' => 'game_entries#reopen'
  get 'game_entries/cancel/:id' => 'game_entries#cancel'
  get 'game_entries/accept/:id' => 'game_entries#accept'
  get 'game_entries/reject/:id' => 'game_entries#reject'

  match '/game_passings/show_results', to: 'game_passings#show_results', via: 'get'
  match '/play/:game_id/tip',  to: 'game_passings#get_current_level_tip', via: 'get'
  match '/play/:game_id',  to: 'game_passings#show_current_level', via: 'get'
  match '/play/:game_id',  to: 'game_passings#post_answer', via: 'post'
  match '/play/:game_id/autocomplete_level',  to: 'game_passings#autocomplete_level', via: 'get'

  match '/stats/:action/:game_id', to: 'game_passings#index', via: 'get'
  match '/logs/livechannel/:game_id', to: 'logs#show_live_channel', via: 'get'
  match '/logs/level/:game_id/:team_id', to: 'logs#show_level_log', via: 'get'
  match '/logs/game/:game_id/:team_id', to: 'logs#show_game_log', via: 'get'
  match '/logs/full/:game_id', to: 'logs#show_full_log', via: 'get'

  match '/game_entries/new/:game_id/:team_id',  to: 'game_entries#new', via: 'get'
  match '/signup',  to: 'users#new',            via: 'get'
  match '/signin',  to: 'sessions#new',         via: 'get'
  match '/signout', to: 'sessions#destroy', via: 'delete'
  match '/signout', to: 'sessions#destroy', via: 'get'
  match '/dashboard', to: 'dashboard#index',         via: 'get'
  match '/team-room', to: 'team_room#index',         via: 'get'

  match '/games/end_game/:id', to: 'games#end_game', via: 'get'
  match '/games/start_test/:id', to: 'games#start_test', via: 'get'
  match '/games/finish_test/:id', to: 'games#finish_test', via: 'get'

  match '/teams/edit/delete_member', to: 'teams#delete_member', via: 'get'
  match '/teams/edit/captain', to: 'teams#captain', via: 'get'
  post '/tinymce_assets' => 'tinymce_assets#create'
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
