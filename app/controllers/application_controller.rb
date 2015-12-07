class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  protected

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :nickname
    devise_parameter_sanitizer.for(:account_update) << :nickname
    devise_parameter_sanitizer.for(:account_update) << :phone_number
  end

  def ensure_team_member
    unless current_user.member_of_any_team?
      redirect_to root_path, alert: 'Ви не авторизовані для відвідування цієї сторінки'
    end
  end

  def ensure_team_captain
    unless current_user.captain?
      redirect_to root_path, alert: 'Ви повинні бути капітаном для виконання цієї дії'
    end
  end

  def ensure_author
    unless user_signed_in? && current_user.author_of?(@game)
      redirect_to root_path, alert: 'Ви повинні бути автором гри, щоб бачити цю сторінку'
    end
  end

  def ensure_game_was_not_started
    redirect_to root_path, alert: 'Заборонено редагувати гру після її початку' if @game.started?      
  end
end
