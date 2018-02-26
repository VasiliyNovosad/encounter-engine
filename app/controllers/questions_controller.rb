class QuestionsController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :find_level
  before_action :find_question, only: [:edit, :update, :move_up, :move_down, :destroy]
  before_action :find_teams, only: [:new, :edit, :create, :update]

  def new
    @question = Question.new(name: "Сектор #{@level.questions.count + 1}")
    @question.level = @level
  end

  def create
    @question = Question.new(question_params)
    @question.level = @level
    @question.answers.each do |answer|
      answer.level = @level
    end
    if @question.save
      redirect_to game_level_path(@level.game, @level)
    else
      render :new
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
      render :edit
    end
  end

  def destroy
    @question.destroy
    redirect_to game_level_path(@level.game, @level)
  end

  def move_up
    @question.move_higher
    redirect_to game_level_path(@level.game, @level)
  end

  def move_down
    @question.move_lower
    redirect_to game_level_path(@level.game, @level)
  end

  protected

  def question_params
    params.require(:question).permit(:name, :team_id, answers_attributes: [:id, :value, :team_id, :_destroy])
  end

  def find_game
    @game = Game.friendly.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_question
    @question = Question.find(params[:id])
  end

  def find_teams
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map { |game_entry| game_entry.team }
  end

end
