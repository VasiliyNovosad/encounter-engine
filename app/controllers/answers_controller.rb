class AnswersController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :find_level
  before_action :find_question
  before_action :find_answers
  before_action :find_answer, only: [:edit, :update, :destroy]
  before_action :find_teams, only: [:new, :edit]

  def index
    render
  end

  def new
    @answer = Answer.new
    @answer.level = @level
    @answer.question = @question
  end

  def create
    @answer = Answer.new(answer_params)
    @answer.level = @level
    @answer.question = @question
    if @answer.save
      redirect_to game_level_path(@game, @level)
    else
      render :new
    end
  end

  def edit
    render
  end

  def update
    @answer.level = @level if @answer.level.nil?
    if @answer.update_attributes(answer_params)
      redirect_to game_level_path(@level.game, @level)
    else
      render 'edit'
    end
  end

  def destroy
    @answer.destroy
    redirect_to game_level_path(@game, @level)
  end

  protected

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_question
    @question = Question.find(params[:question_id])
  end

  def find_answer
    @answer = Answer.find(params[:id])
  end

  def find_answers
    @answers = Answer.of_question(@question)
  end

  def answer_params
    params.require(:answer).permit(:value, :team_id)
  end

  def find_teams
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
  end

end
