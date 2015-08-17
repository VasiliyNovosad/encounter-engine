class AnswersController < ApplicationController
  before_filter :find_game
  before_filter :ensure_author
  before_filter :find_level
  before_filter :find_question
  before_filter :find_answers
  before_filter :find_answer, :only => [:delete]
  before_filter :build_answer, :only => [:create]
  before_filter :build_answer_index, :only => [:index]

  def index
    render
  end

  def create
    if @answer.save
      redirect_to game_level_question_answers_path(@game, @level, @question)
    else
      render 'index'
    end
  end

  def destroy
    if @answers.count > 1
      @answer.destroy
      redirect_to game_level_question_answers_path(@game, @level, @question)
    else
      build_answer
      @answer.errors.add(:question, "Повинен бути хоча б один варіант коду")
      render :index
    end
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

  def build_answer
    @answer = Answer.new(answer_params)
    @answer.level = @level
    @answer.question = @question
  end

  def build_answer_index
    @answer = Answer.new
    @answer.level = @level
    @answer.question = @question
  end

  def answer_params
    params.require(:answer).permit(:value)
  end
end
