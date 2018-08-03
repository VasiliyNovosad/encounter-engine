class QuestionsController < ApplicationController
  before_action :find_game
  before_action :ensure_game_was_not_finished, except: [:show]
  before_action :ensure_author
  before_action :find_level
  before_action :find_question, only: [:edit, :update, :move_up, :move_down, :destroy, :copy, :copy_to_bonus]
  before_action :find_teams, only: [:new, :edit, :create, :update]

  def new
    @question = @level.questions.build(name: "Сектор #{@level.questions.count + 1}")
    @question.answers.build
  end

  def create
    @question = @level.questions.build(question_params)
    @question.answers.each do |answer|
      answer.level = @level
    end
    if @question.save
      redirect_to game_level_path(@level.game, @level, anchor: "question-#{@question.id}")
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
      redirect_to game_level_path(@question.level.game, @question.level, anchor: "question-#{@question.id}")
    else
      render :edit
    end
  end

  def destroy
    @question.destroy
    redirect_to game_level_path(@level.game, @level, anchor: "sectors-block")
  end

  def move_up
    @question.move_higher
    redirect_to game_level_path(@level.game, @level, anchor: "question-#{@question.id}")
  end

  def move_down
    @question.move_lower
    redirect_to game_level_path(@level.game, @level, anchor: "question-#{@question.id}")
  end



  def copy
    @new_question = @question.dup
    @new_question.name = "Сектор #{@level.questions.count + 1}"
    @new_question.set_list_position(@level.questions.count + 1)
    @question.answers.each do |answer|
      new_answer = answer.dup
      new_answer.question_id = nil
      @new_question.answers << new_answer
    end
    if @new_question.save
      redirect_to game_level_path(@level.game, @level, anchor: "question-#{@new_question.id}")
    else
      p @new_question.errors
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@level.game, @level, anchor: "question-#{@question.id}")
    end
  end

  def copy_to_bonus
    @new_bonus = @level.bonuses.build(name: "Бонус #{@level.bonuses.count + 1}")
    @new_bonus.set_list_position(@level.bonuses.count + 1)
    @question.answers.each do |answer|
      @new_bonus.bonus_answers.build(value: answer.value, team_id: answer.team_id)
    end
    if @new_bonus.save
      redirect_to game_level_path(@level.game, @level, anchor: "bonus-#{@new_bonus.id}")
    else
      p @new_bonus.errors
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@level.game, @level, anchor: "question-#{@question.id}")
    end
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
