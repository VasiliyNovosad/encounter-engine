class ApplicationController < ActionController::Base
  
  before_filter :find_user_from_session
  protect_from_forgery with: :exception
  
  include SharedFilters
  include SessionsHelper


  def logged_in?
    !! @current_user
  end

protected

  def find_user_from_session
    @current_user = current_user
  end  

  def ensure_team_member
    current_user.member_of_any_team?
  end

  def ensure_team_captain
    current_user.captain?
  end

  def ensure_author
    logged_in? and @current_user.author_of?(@game)
  end

  def ensure_game_was_not_started
    @game.started?
  end

end
