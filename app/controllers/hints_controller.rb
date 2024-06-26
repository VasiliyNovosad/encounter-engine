class HintsController < ApplicationController
  before_action :find_level
  before_action :find_game
  before_action :ensure_game_was_not_finished
  before_action :find_hint, only: [:edit, :update, :destroy, :copy]
  before_action :find_teams, only: [:new, :edit, :create, :update]

  before_action :ensure_author
  before_action :ensure_game_was_not_started, only: [:new, :create, :edit, :update]

  def new
    @hint = @level.hints.build
  end

  def create
    @hint = @level.hints.build(hint_params)
    if @hint.save
      redirect_to game_level_path(@game, @level, anchor: "hint-#{@hint.id}")
    else
      render :new
    end
  end

  def edit
    render
  end

  def update
    if @hint.update(hint_params)
      redirect_to game_level_path(@game, @level, anchor: "hint-#{@hint.id}")
    else
      render :edit
    end
  end

  def destroy
    @hint.destroy
    redirect_to game_level_path(@game, @level, anchor: "hints-block")
  end

  def copy
    new_hint = @hint.dup
    if new_hint.save
      redirect_to game_level_path(@game, @level, anchor: "hint-#{new_hint.id}")
    else
      redirect_to game_level_path(@game, @level, anchor: "hint-#{@hint.id}")
    end
  end

  protected

  def hint_params
    params.require(:hint).permit(:level_id, :text, :delay, :team_id)
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_game
    @game = @level.game
  end

  def find_hint
    @hint = Hint.find(params[:id])
  end

end
