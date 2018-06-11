class BonusAnswersController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :find_level
  before_action :find_bonus
  before_action :find_bonus_answers
  before_action :find_bonus_answer, only: [:edit, :update, :destroy]
  before_action :find_teams, only: [:new, :edit, :create, :update]

  def index
    render
  end

  def new
    @bonus_answer = @bonus.bonus_answers.create
  end

  def create
    @bonus_answer = @bonus.bonus_answers.create(bonus_answer_params)
    if @bonus_answer.save
      redirect_to game_level_path(@game, @level)
    else
      render :new
    end
  end

  def edit
    render
  end

  def update
    if @bonus_answer.update_attributes(bonus_answer_params)
      redirect_to game_level_path(@level.game, @level)
    else
      render 'edit'
    end
  end

  def destroy
    @bonus_answer.destroy
    redirect_to game_level_path(@game, @level)
  end

  protected

  def find_game
    @game = Game.friendly.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_bonus
    @bonus = Bonus.find(params[:bonus_id])
  end

  def find_bonus_answer
    @bonus_answer = BonusAnswer.find(params[:id])
  end

  def find_bonus_answers
    @bonus_answers = BonusAnswer.of_bonus(@bonus)
  end

  def bonus_answer_params
    params.require(:bonus_answer).permit(:value, :team_id)
  end

  def find_teams
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
  end
end