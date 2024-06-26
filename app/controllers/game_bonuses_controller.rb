class GameBonusesController < ApplicationController
  before_action :find_game
  before_action :find_game_bonus, only: %i[edit update destroy]
  before_action :find_teams, only: %i[new edit create update]

  before_action :ensure_author, only: %i[new create edit update destroy]

  def index
    @game_bonuses = GameBonus.of_game(@game.id)
    @game_bonuses = @game_bonuses.where(team_id: params[:team_id]) unless params[:team_id].nil?
    @game_bonuses = @game_bonuses.where(level_id: params[:level_id]) unless params[:level_id].nil?
    @game_bonuses = @game_bonuses.where('award > 0') unless params[:type].nil? || params[:type] != 'bonus'
    @game_bonuses = @game_bonuses.where('award < 0') unless params[:type].nil? || params[:type] != 'penalty'
    @game_bonuses = @game_bonuses.order(:created_at)
  end

  def new
    @game_bonus = @game.game_bonuses.build(reason: 'додано автором')
  end

  def create
    @game_bonus = @game.game_bonuses.build(game_bonus_params)
    @game_bonus.user = current_user
    if @game_bonus.save
      redirect_to game_game_bonuses_path(@game)
    else
      render 'new'
    end
  end

  def edit
    render
  end

  def update
    if @game_bonus.update(game_bonus_params)
      redirect_to game_game_bonuses_path(@game)
    else
      render 'edit'
    end
  end

  def destroy
    @game_bonus.destroy
    redirect_to game_game_bonuses_path(@game)
  end

  protected

  def game_bonus_params
    params.require(:game_bonus).permit(
      :game_id, :team_id, :level_id, :award,
      :description, :user_id, :reason
    )
  end

  def find_game
    @game = Game.friendly.find(params[:game_id])
  end

  def find_game_bonus
    @game_bonus = GameBonus.find(params[:id])
  end

end