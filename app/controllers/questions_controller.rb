class QuestionsController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :find_level

  def new
    @question = Question.new
    @question.level = @level
  end

  def create
    @question = Question.create(question_params)
    @question.level = @level
    if @question.save
      @answer = @question.answers.first
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

  protected

  def question_params
    params.require(:question).permit!
  end

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:level_id])
  end
end
