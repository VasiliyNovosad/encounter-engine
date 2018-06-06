class PenaltyHintsController < ApplicationController
  before_action :find_level
  before_action :find_game
  before_action :find_penalty_hint, only: [:edit, :update, :destroy]
  before_action :find_teams, only: [:new, :edit, :create, :update]

  before_action :ensure_author
  before_action :ensure_game_was_not_started, only: [:new, :create, :edit, :update]

  def new
    @penalty_hint = PenaltyHint.new
    @penalty_hint.level = @level
  end

  def create
    @penalty_hint = PenaltyHint.new(penalty_hint_params)
    @penalty_hint.level = @level
    if @penalty_hint.save
      redirect_to game_level_path(@game, @level)
    else
      render 'new'
    end
  end

  def edit
    render
  end

  def update
    if @penalty_hint.update_attributes(penalty_hint_params)
      redirect_to game_level_path(@level.game, @level)
    else
      render 'edit'
    end
  end

  def destroy
    @penalty_hint.destroy
    redirect_to game_level_path(@level.game, @level)
  end

  protected

  def penalty_hint_params
    params.require(:penalty_hint).permit(:level_id, :name, :text, :penalty, :team_id)
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_game
    @game = @level.game
  end

  def find_penalty_hint
    @penalty_hint = PenaltyHint.find(params[:id])
  end

  def find_teams
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
  end

end
