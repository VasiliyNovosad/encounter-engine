class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  # def forem_user
  #   current_user
  # end

  def seconds_to_string(s)
    sign = s < 0 ? '-' : ''

    # d = days, h = hours, m = minutes, s = seconds
    m = (s.abs / 60).floor
    s = s.abs % 60
    h = (m / 60).floor
    m = m % 60
    d = (h / 24).floor
    h = h % 24

    output = sign
    output << "#{d} дн" if (d > 0)
    output << " #{h} г" if (h > 0)
    output << " #{m} хв" if (m > 0)
    output << " #{s} с" if (s > 0)

    output
  end

  # helper_method :forem_user
  helper_method :seconds_to_string

  protected

  def configure_devise_permitted_parameters
    # devise_parameter_sanitizer.for(:sign_up) << :nickname
    # devise_parameter_sanitizer.for(:account_update) << :nickname
    # devise_parameter_sanitizer.for(:account_update) << :phone_number
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nickname])
    devise_parameter_sanitizer.permit(:account_update, keys: [:nickname, :phone_number, :telegram])
  end

  def ensure_team_member
    unless  user_signed_in? && (current_user.member_of_any_team? || @game&.team_type == 'single')
      redirect_to root_path, alert: 'Ви не авторизовані для відвідування цієї сторінки'
    end
  end

  def ensure_team_captain
    unless  user_signed_in? && (current_user.captain? || @game.team_type == 'single')
      redirect_to root_path, alert: 'Ви повинні бути капітаном для виконання цієї дії'
    end
  end

  def ensure_author
    unless user_signed_in? && current_user.author_of?(@game)
      redirect_to root_path, alert: 'Ви повинні бути автором гри, щоб бачити цю сторінку'
    end
  end

  def ensure_game_was_not_started
    #redirect_to root_path, alert: 'Заборонено редагувати гру після її початку' if @game.started?      
  end

  def ensure_game_was_not_finished
    redirect_to root_path, alert: 'Заборонено редагувати гру після її закриття' if @game.author_finished?
  end
end
