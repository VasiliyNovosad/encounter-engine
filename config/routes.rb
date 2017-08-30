Rails.application.routes.draw do
  devise_for :users

  root 'games#index'

  resources :teams

  resources :invitations do
    get 'accept', on: :member
    get 'reject', on: :member
    get :autocomplete_user_nickname, on: :collection
  end

  resources :users do
    resources :games
  end

  resources :games do
    resources :levels do
      resources :tasks
      resources :hints
      resources :questions do
        resources :answers
      end
      resources :bonuses do
        resources :bonus_answers
      end

      get 'move_up', on: :member
      get 'move_down', on: :member
    end
    get 'show_scenario', on: :member
    get 'new_level_order', on: :member
    post 'create_level_order', on: :member
  end

  get 'game_entries/recall/:id' => 'game_entries#recall'
  get 'game_entries/reopen/:id' => 'game_entries#reopen'
  get 'game_entries/cancel/:id' => 'game_entries#cancel'
  get 'game_entries/accept/:id' => 'game_entries#accept'
  get 'game_entries/reject/:id' => 'game_entries#reject'
  get 'game_entries/reaccept/:id' => 'game_entries#reaccept'

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
  match '/logs/short/:game_id', to: 'logs#show_short_log', via: 'get'

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
  match '/teams/edit/captain', to: 'teams#make_member_captain', via: 'get'
  post '/tinymce_assets' => 'tinymce_assets#create'
end
