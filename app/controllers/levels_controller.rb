class LevelsController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :ensure_game_was_not_started, except: [:show, :index, :move_up, :move_down]
  before_action :find_level, except: [:new, :index, :create]

  def new
    @level = Level.new
    @level.game = @game
    @level.questions.build
    @level.questions.first.answers.build
  end

  def create
    @level = Level.new(level_params)
    @level.game = @game
    if @level.save
      redirect_to game_level_path(@game, @level)
    else
      render 'new'
    end
  end

  def show
    render
  end

  def edit
    render
  end

  def update
    if @level.update_attributes(level_params)
      redirect_to game_level_path(@level.game, @level)
    else
      render 'edit'
    end
  end

  def destroy
    @level.destroy
    redirect_to game_path(@game)
  end

  def move_up
    @level.move_higher
    redirect_to game_path(@game)
  end

  def move_down
    @level.move_lower
    redirect_to game_path(@game)
  end

  protected

  def level_params
    params.require(:level).permit(:name, :text, :correct_answer)
  end

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:id])
  end
end
