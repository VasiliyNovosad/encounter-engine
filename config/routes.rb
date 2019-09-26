Rails.application.routes.draw do

  # This line mounts Forem's routes at /forums by default.
  # This means, any requests to the /forums URL of your application will go to Forem::ForumsController#index.
  # If you would like to change where this extension is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Forem relies on it being the default of "forem"
  mount Forem::Engine, :at => '/forums'

  devise_for :users

  root 'games#index'

  resources :teams

  resources :invitations do
    post 'accept', on: :member
    post 'reject', on: :member
  end

  resources :team_requests do
    post 'accept', on: :member
    post 'reject', on: :member
  end

  resources :users do
    resources :games
  end

  resources :games do
    resources :levels do
      resources :tasks
      resources :hints do
        post 'copy', on: :member
      end
      resources :penalty_hints do
        post 'copy', on: :member
      end
      resources :questions do
        resources :answers
        collection do
          get  :new_batch
          post :create_batch
        end
        post 'move_up', on: :member
        post 'move_down', on: :member
        post 'copy', on: :member
        post 'copy_to_bonus', on: :member
      end
      resources :bonuses do
        resources :bonus_answers
        post 'move_up', on: :member
        post 'move_down', on: :member
        post 'copy', on: :member
        post 'copy_to_sector', on: :member
      end
      resources :messages
      post 'move_up', on: :member
      post 'move_down', on: :member
      post 'change_position', on: :member
      post 'copy', on: :member
      post 'dismiss', on: :member
      post 'undismiss', on: :member
      post 'add_answer_to_sectors', on: :member
      post 'add_answer_to_bonuses', on: :member
    end
    resources :game_bonuses
    get 'show_scenario', on: :member
    get 'new_level_order', on: :member
    post 'create_level_order', on: :member
    post 'end_game', on: :member
    post 'open_game', on: :member
    post 'start_test', on: :member
    post 'finish_test', on: :member
  end

  match '/game_entries/recall/:id', to: 'game_entries#recall', via: 'post'
  match '/game_entries/reopen/:id', to: 'game_entries#reopen', via: 'post'
  match '/game_entries/cancel/:id', to: 'game_entries#cancel', via: 'post'
  match '/game_entries/accept/:id', to: 'game_entries#accept', via: 'post'
  match '/game_entries/reject/:id', to: 'game_entries#reject', via: 'post'
  match '/game_entries/reaccept/:id', to: 'game_entries#reaccept', via: 'post'
  match '/game_entries/new/:game_id/:team_id',  to: 'game_entries#new', via: 'post'

  match '/game_passings/show_results', to: 'game_passings#show_results', via: 'get'
  match '/play/:game_id/tip', to: 'game_passings#get_current_level_tip', via: 'get'
  match '/play/:game_id', to: 'game_passings#show_current_level', via: 'get'
  match '/play/:game_id', to: 'game_passings#post_answer', via: 'post'
  match '/play/:game_id/autocomplete_level', to: 'game_passings#autocomplete_level', via: 'get'
  match '/play/:game_id/penalty_hint', to: 'game_passings#use_penalty_hint', via: 'post'
  match '/play/:game_id/penalty_hint', to: 'game_passings#show_penalty_hint', via: 'get'
  match '/play/:game_id/bonus', to: 'game_passings#get_current_level_bonus', via: 'get'
  match '/play/:game_id/miss_bonus', to: 'game_passings#miss_current_level_bonus', via: 'post'

  match '/stats/:action/:game_id', to: 'game_passings#index', via: 'get'
  match '/logs/livechannel/:game_id', to: 'logs#show_live_channel', via: 'get'
  match '/logs/level/:game_id/:team_id', to: 'logs#show_level_log', via: 'get'
  match '/logs/game/:game_id/:team_id', to: 'logs#show_game_log', via: 'get'
  match '/logs/full/:game_id', to: 'logs#show_full_log', via: 'get'
  match '/logs/short/:game_id', to: 'logs#show_short_log', via: 'get'
  match '/logs/special/:game_id', to: 'logs#show_special_results', via: 'get'

  match '/signup',  to: 'users#new',            via: 'get'
  match '/signin',  to: 'sessions#new',         via: 'get'
  match '/signout', to: 'sessions#destroy', via: 'delete'
  match '/signout', to: 'sessions#destroy', via: 'get'
  match '/dashboard', to: 'dashboard#index',         via: 'get'
  match '/team-room', to: 'team_room#index',         via: 'get'

  match '/teams/edit/delete_member', to: 'teams#delete_member', via: 'post'
  match '/teams/edit/captain', to: 'teams#make_member_captain', via: 'post'
  match '/teams/edit/leave_team', to: 'teams#leave_team', via: 'post'
  match '/tinymce_assets', to: 'tinymce_assets#create', via: 'post'
  match '/help', to: 'help#index', via: 'get'
end
