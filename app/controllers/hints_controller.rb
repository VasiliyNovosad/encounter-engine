class HintsController < ApplicationController
  before_action :find_level
  before_action :find_game
  before_action :find_hint, only: [:edit, :update, :destroy]

  before_action :ensure_author
  before_action :ensure_game_was_not_started, only: [:new, :create, :edit, :update]

  def new
    @hint = Hint.new
    @hint.level = @level
  end

  def create
    @hint = Hint.create(hint_params)
    @hint.level = @level
    if @hint.save
      redirect_to game_level_path(@game, @level)
    else
      render 'new'
    end
  end

  def edit
    render
  end

  def update
    if @hint.update_attributes(hint_params)
      redirect_to game_level_path(@level.game, @level)
    else
      render 'edit'
    end
  end

  def destroy
    @hint.destroy
    redirect_to game_level_path(@level.game, @level)
  end

  protected

  def hint_params
    params.require(:hint).permit(:level_id, :text, :delay_in_minutes)
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
