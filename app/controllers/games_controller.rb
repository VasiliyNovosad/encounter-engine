class GamesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :find_game, only: [:show, :edit, :update, :delete, :end_game, :destroy]
  before_action :find_team, only: [:show]
  before_action :ensure_author_if_game_is_draft, only: [:show]
  before_action :ensure_author_if_no_start_time, only: [:show]
  before_action :ensure_author, only: [:edit, :update]
  before_action :ensure_game_was_not_started, only: [:edit, :update]
  before_action :max_team_number_from_nz, only: [:update]

  def index
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
    @game = Game.create(game_params)
    @game.author = current_user
    if @game.save
      redirect_to game_path(@game)
    else
      render 'new'
    end
  end

  def show
    @game_entries = GameEntry.of_game(@game).with_status('new')
    @teams = []
    @levels = @game.levels
    GameEntry.of_game(@game).with_status('accepted').each do |entry|
      @teams << Team.find(entry.team_id)
    end
    render
  end

  def edit
    render
  end

  def update
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
    game.is_draft = 'f'
    game.is_testing = 't'
    game.test_date = game.starts_at
    game.starts_at = Time.now + 0.1.second
    game.registration_deadline = nil
    game.save!
    sleep(rand(1))

    redirect_to game_path(@game)
  end

  def finish_test
    game = find_game
    game.is_draft = 't'
    game.is_testing = 'f'
    game.starts_at = game.test_date
    game.test_date = Time.now
    game.save!

    game_passing = GamePassing.of_game(game)
    logs = Log.of_game(game)

    game_passing.delete_all
    logs.delete_all

    redirect_to game_path(@game)
  end

  protected

  def game_params
    params.require(:game).permit(:name, :description, :starts_at, :registration_deadline, :max_team_number, :is_draft, :is_testing, :author, :test_date)
  end

  def find_game
    @game = Game.find(params[:id])
  end

  def game_is_draft?
    @game.draft?
  end

  def find_team
    if current_user
      @team = current_user.team
    else
      @team = nil
    end
  end

  def no_start_time?
    @game.starts_at.nil?
  end

  def ensure_author_if_game_is_draft
    ensure_author if game_is_draft?
  end

  def ensure_author_if_no_start_time
    ensure_author if no_start_time?
  end

  def max_team_number_from_nz
    @game.max_team_number = 10_000 if @game.max_team_number.nil? || @game.max_team_number.equal?(0)
  end
end
