class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  # def forem_user
  #   current_user
  # end

  def seconds_to_string(seconds)
    sign = seconds.negative? ? '-' : ''

    minutes = (seconds.abs / 60).floor
    seconds = seconds.abs % 60
    hours = (minutes / 60).floor
    minutes = minutes % 60
    days = (hours / 24).floor
    hours = hours % 24

    output = sign
    output << "#{days} дн" if days.positive?
    output << " #{hours} г" if hours.positive?
    output << " #{minutes} хв" if minutes.positive?
    output << " #{seconds} с" if seconds.positive?

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

  def ensure_game_is_not_in_testing
    redirect_to game_path(@game), alert: 'Гра в режимі тестування!!!' if @game.is_testing? && @game.created_by?(current_user)
  end

  def find_teams
    @teams = [['Для всіх', nil]] + GameEntry.of_game(@game.id).where("status in ('new', 'accepted')").includes(:team).map do |game_entry|
      team = game_entry.team
      [team.name, team.id]
    end
  end
end
