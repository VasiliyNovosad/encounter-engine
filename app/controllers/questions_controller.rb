class QuestionsController < ApplicationController
  before_action :find_game
  before_action :ensure_game_was_not_finished, except: :show
  before_action :ensure_author
  before_action :find_level
  before_action :find_question, only: %i[edit update move_up move_down destroy copy copy_to_bonus]
  before_action :find_teams, only: %i[new edit create update new_batch create_batch]

  def new
    questions = @level.questions
    @question = questions.build(name: "Сектор #{questions.count + 1}")
    @question.answers.build
  end

  def create
    @question = @level.questions.build(question_params)
    @question.answers.each do |answer|
      answer.level = @level
    end
    if @question.save
      redirect_to game_level_path(@game, @level, anchor: "question-#{@question.id}")
    else
      render :new
    end
  end

  def edit
    render
  end

  def show
    redirect_to game_level_path(@game, @level)
  end

  def update
    if @question.update_attributes(question_params)
      redirect_to game_level_path(@game, @level, anchor: "question-#{@question.id}")
    else
      render :edit
    end
  end

  def destroy
    @question.destroy
    redirect_to game_level_path(@game, @level, anchor: "sectors-block")
  end

  def move_up
    @question.move_higher
    redirect_to game_level_path(@game, @level, anchor: "question-#{@question.id}")
  end

  def move_down
    @question.move_lower
    redirect_to game_level_path(@game, @level, anchor: "question-#{@question.id}")
  end

  def new_batch
    @question = @level.questions.build(name: 'Сектор')
  end

  def create_batch
    team_id = question_params[:team_id]
    questions = @level.questions
    question_params[:answers_list].split(/\n+/).each do |answers|
      name_with_answers = answers.split('|')
      all_answers = if name_with_answers.count == 1
                      answers.split(';')
                    else
                      name_with_answers[1].split(';')
                    end
      sector_name = if name_with_answers.count == 1
                      "#{question_params[:name]} #{questions.count + 1}"
                    else
                      name_with_answers[0]
                    end
      question = questions.build(
        name: sector_name,
        team_id: team_id,
        change_level_autocomplete: question_params[:change_level_autocomplete],
        change_level_autocomplete_by: question_params[:change_level_autocomplete_by]
      )
      all_answers.each do |answer|
        question.answers.build(value: answer, team_id: team_id)
      end
      question.save!
    end
    redirect_to game_level_path(@game, @level)
  end

  def copy
    questions_count = @level.questions.count
    new_question = @question.dup
    new_question.name = "Сектор #{questions_count + 1}"
    new_question.set_list_position(questions_count + 1)
    @question.answers.each do |answer|
      new_answer = answer.dup
      new_answer.question_id = nil
      new_question.answers << new_answer
    end
    if new_question.save
      redirect_to game_level_path(@game, @level, anchor: "question-#{new_question.id}")
    else
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@game, @level, anchor: "question-#{@question.id}")
    end
  end

  def copy_to_bonus
    bonuses = @level.bonuses
    new_bonus = bonuses.build(name: "Бонус #{bonuses.count + 1}")
    new_bonus.set_list_position(bonuses.count + 1)
    @question.answers.each do |answer|
      new_bonus.bonus_answers.build(value: answer.value, team_id: answer.team_id)
    end
    if new_bonus.save
      redirect_to game_level_path(@game, @level, anchor: "bonus-#{new_bonus.id}")
    else
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@game, @level, anchor: "question-#{@question.id}")
    end
  end

  protected

  def question_params
    params.require(:question).permit(
      :name, :team_id, :answers_list,
      :change_level_autocomplete, :change_level_autocomplete_by,
      answers_attributes: %i[
        id value team_id _destroy
      ]
    )
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

end
