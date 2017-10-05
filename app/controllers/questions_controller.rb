class QuestionsController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :find_level
  before_action :find_question, only: [:edit, :update, :move_up, :move_down, :destroy]
  before_action :find_teams, only: [:new, :edit]

  def new
    @question = Question.new
    @question.level = @level
  end

  def create
    @question = Question.new(question_params)
    @question.level = @level
    if @question.save
      @answer = @question.answers.first
      @answer.level = @level
      if @answer.save
        redirect_to game_level_path(@level.game, @level)
      else
        @question.destroy
        render 'new'
      end
    else
      render 'new'
    end
  end

  def edit
  end

  def show
    redirect_to game_level_path(@level.game, @level)
  end

  def update
    if @question.update_attributes(question_params)
      redirect_to game_level_question_path(@question.level.game, @question.level, @question)
    else
      render 'edit'
    end
  end

  def destroy
    @question.answers.each { |answer| answer.destroy }
    @question.destroy
    redirect_to game_level_path(@level.game, @level)
  end

  protected

  def question_params
    params.require(:question).permit(:name, :correct_answer, :team_id)
  end

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_question
    @question = Question.find(params[:id])
  end

  def find_teams
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
  end

end
