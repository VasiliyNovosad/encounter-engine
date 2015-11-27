class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include SharedFilters

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  protected

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :nickname
    devise_parameter_sanitizer.for(:account_update) << :nickname
    devise_parameter_sanitizer.for(:account_update) << :phone_number
  end

  def ensure_team_member
    current_user.member_of_any_team?
  end

  def ensure_team_captain
    current_user.captain?
  end

  def ensure_author
    current_user && current_user.author_of?(@game)
  end

  def ensure_game_was_not_started
    @game.started?
  end
end
