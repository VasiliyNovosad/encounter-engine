class GamesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :find_game, except: [:index, :new, :create]
  before_action :find_team, only: [:show]
  before_action :ensure_author_if_game_is_draft, only: [:show]
  before_action :ensure_author_if_no_start_time, only: [:show]
  before_action :ensure_author, only: [:edit, :update]
  #before_action :ensure_game_was_not_started, only: [:edit, :update]
  before_action :max_team_number_from_nz, only: [:update]
  before_action :ensure_author_if_no_finish_time, only: [:show_scenario]
  before_action :find_teams, only: [:show, :new_level_order]

  def index
    @page_content = "index,follow"
    if params[:user_id].blank?
      @games = Game.non_drafts
    else
      user = User.find(params[:user_id])
      @games = user.created_games
    end
    render
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    @game.author = current_user
    @authors = User.where(id: params[:organizing_team])
    @game.authors << @authors
    if @game.save
      redirect_to game_path(@game)
    else
      render 'new'
    end
  end

  def show
    if request.path != game_path(@game)
      return redirect_to @game, :status => :moved_permanently
    end
    @page_title = "#{@game.name} ᐈ【 Квести Луцьк 】"
    @page_description = "❰❰❰ #{@game.name} ❱❱❱ #{@game.small_description || "це: ➔ цікаві логічні завдання від кращих авторів Луцька, ➔ захоплюючі пошуки, ➔ драйв та адреналін, ➔ неймовірні пригоди та яскраві емоції, ➔ новий формат інтелектуально-активного відпочинку! ➤ Якщо ти рухаєш мізками та дупою швидше ніж твоя бабуся, ПРИЄДНУЙСЯ"} ➤【 Квест 🔍 Луцьк 】 />"
    @page_content = "index,follow"
    @teams_for_test = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
    @game_entries = GameEntry.of_game(@game).with_status('new')
    @levels = @game.levels
    @topic = Forem::Topic.find(@game.topic_id) unless @game.topic_id.nil?
    render
  end

  def edit
    render
  end

  def update
    @authors = User.where(id: params[:organizing_team])
    @game.authors.destroy_all
    @game.authors << @authors
    if @game.update_attributes(game_params)
      redirect_to game_path(@game)
    else
      render 'edit'
    end
  end

  def delete
    @game.destroy
    redirect_to dashboard_path
  end

  def destroy
    @game.levels.each(&:destroy)
    @game.destroy
    redirect_to dashboard_path
  end

  def end_game
    @game.finish_game!
    game_passings = GamePassing.of_game(@game)
    game_passings.each(&:end!)
    redirect_to dashboard_path
  end

  def start_test
    game = find_game
    # game.is_draft = 'f'
    game.is_testing = 't'
    game.test_date = game.starts_at
    game.starts_at = Time.zone.now + 0.1.second
    game.registration_deadline = nil
    game.tested_team_id = params[:team_id]
    game.save!
    sleep(rand(1))

    redirect_to game_path(@game)
  end

  def finish_test
    game = find_game
    # game.is_draft = 't'
    game.is_testing = 'f'
    game.starts_at = game.test_date
    game.test_date = Time.zone.now
    game.tested_team_id = nil
    game.save!

    game_passing = GamePassing.of_game(game)
    logs = Log.of_game(game)

    game_passing.delete_all
    logs.delete_all

    redirect_to game_path(@game)
  end

  def show_scenario
  end

  def new_level_order
    @levels = @game.levels
    @level_orders = {}
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
    (1..@levels.count).each do |index|
      levels = {}
      @teams.each do |team|
        ordered_level = LevelOrder.of(@game, team).where(position: index).first
        new_level = @levels.where(position: index).first
        levels[team.id] = (ordered_level.nil? ? new_level.id : ordered_level.level_id)
      end
      @level_orders[index] = levels
    end
    render
  end

  def create_level_order
    @levels = @game.levels
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
    (1..@levels.count).each do |index|
      @teams.each do |team|
        selected_level = params["level_id_#{index}_#{team.id}"]
        level_order = LevelOrder.where(game_id: @game.id, team_id: team.id, position: index).first
        if level_order.nil?
          level_order = LevelOrder.create!(game_id: @game.id, team_id: team.id, level_id: selected_level, position: index)
        else
          level_order.update!(game_id: @game.id, team_id: team.id, level_id: selected_level, position: index)
        end
      end
    end
    redirect_to game_path(@game)
  end

  protected

  def game_params
    params.require(:game).permit(
      :name, :description, :game_type, :duration, :starts_at,
      :registration_deadline, :max_team_number, :is_draft,
      :is_testing, :author, :test_date, :tested_team_id, :game_size,
      :price, :place, :city, :small_description, :image
    )
  end

  def find_game
    @game = Game.friendly.find(params[:id])
  end

  def game_is_draft?
    @game.draft?
  end

  def find_team
    @team = current_user ? current_user.team : nil
  end

  def find_teams
    @accepted_game_entries = GameEntry.of_game(@game).with_status('accepted')
  end

  def no_start_time?
    @game.starts_at.nil?
  end

  def no_finish_time?
    @game.author_finished_at.nil?
  end

  def ensure_author_if_game_is_draft
    ensure_author if game_is_draft?
  end

  def ensure_author_if_no_start_time
    ensure_author if no_start_time?
  end

  def ensure_author_if_no_finish_time
    ensure_author if no_finish_time?
  end

  def max_team_number_from_nz
    @game.max_team_number = 10_000 if @game.max_team_number.nil? || @game.max_team_number.equal?(0)
  end
end
