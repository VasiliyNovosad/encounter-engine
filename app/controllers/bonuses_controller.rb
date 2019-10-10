class BonusesController < ApplicationController
  before_action :find_game
  before_action :ensure_game_was_not_finished, except: :show
  before_action :ensure_author
  before_action :find_level
  before_action :find_bonus, only: %i[edit update move_up move_down destroy copy copy_to_sector]
  before_action :find_teams, only: %i[new edit create update new_batch create_batch]

  def new
    bonuses = @game.bonuses
    @bonus = bonuses.build(name: "Бонус #{bonuses.size + 1}")
    @bonus.bonus_answers.build
    render :new, locals: { teams: @teams, game: @game, bonus: @bonus, level: @level }
  end

  def create
    params[:bonus][:level_ids] ||= [@level.id]
    @bonus = @game.bonuses.build(bonus_params)
    if @bonus.save
      redirect_to game_level_path(@game, @level, anchor: "bonus-#{@bonus.id}")
    else
      render :new,  locals: { teams: @teams, game: @game, bonus: @bonus, level: @level }
    end
  end

  def new_batch
    @bonus = @game.bonuses.build(name: 'Бонус')
    render :new_batch, locals: { teams: @teams, game: @game, bonus: @bonus, level: @level }
  end

  def create_batch
    params[:bonus][:level_ids] ||= [@level.id]
    answers_list = bonus_params[:answers_list].split(/\n+/)
    answers_list.each do |answers|
      all_answers = answers.split(';')
      bonus = @game.bonuses.build(bonus_params.to_hash.merge(name: "#{bonus_params[:name]} #{@level.bonuses.size + 1}"))
      all_answers.each do |answer|
        bonus.bonus_answers.build(value: answer, team_id: bonus_params[:team_id])
      end
      bonus.save!
    end
    redirect_to game_level_path(@game, @level, anchor: 'bonuses-block')
  end

  def edit
    render :edit, locals: { teams: @teams, game: @game, bonus: @bonus, level: @level }
  end

  def show
    redirect_to game_level_path(@game, @level)
  end

  def update
    params[:bonus][:level_ids] ||= [@level.id]
    if @bonus.update_attributes(bonus_params)
      redirect_to game_level_path(@game, @level, anchor: "bonus-#{@bonus.id}")
    else
      render :edit, locals: { teams: @teams, game: @game, bonus: @bonus, level: @level }
    end
  end

  def destroy
    @bonus.destroy
    redirect_to game_level_path(@game, @level, anchor: 'bonuses-block')
  end

  def move_up
    @bonus.move_higher
    redirect_to game_level_path(@game, @level, anchor: "bonus-#{@bonus.id}")
  end

  def move_down
    @bonus.move_lower
    redirect_to game_level_path(@game, @level, anchor: "bonus-#{@bonus.id}")
  end

  def copy
    new_bonus = @bonus.dup
    new_bonus.name = "Бонус #{@level.bonuses.size + 1}"
    new_bonus.set_list_position(@game.bonuses.size + 1)
    @bonus.bonus_answers.each do |answer|
      new_answer = answer.dup
      new_answer.bonus_id = nil
      new_bonus.bonus_answers << new_answer
    end
    @bonus.levels.each do |level|
      new_bonus.levels << level
    end
    if new_bonus.save
      redirect_to game_level_path(@game, @level, anchor: "bonus-#{new_bonus.id}")
    else
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@game, @level, anchor: "bonus-#{@bonus.id}")
    end
  end

  def copy_to_sector
    questions = @level.questions
    new_question = questions.build(name: "Сектор #{questions.size + 1}")
    new_question.set_list_position(questions.size + 1)
    @bonus.bonus_answers.each do |answer|
      new_question.answers.build(value: answer.value, team_id: answer.team_id)
    end
    if new_question.save
      redirect_to game_level_path(@game, @level, anchor: "question-#{new_question.id}")
    else
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@game, @level, anchor: "bonus-#{@bonus.id}")
    end
  end

  protected

  def bonus_params
    params.require(:bonus).permit(
      :name, :task, :help, :award_time, :correct_answer, :team_id,
      :is_absolute_limited, :valid_from, :valid_to, :is_delayed,
      :delay_for, :is_relative_limited, :valid_for,
      :answers_list, level_ids: [],
      bonus_answers_attributes: %i[id value team_id _destroy]
    )
  end

  def find_game
    @game = Game.friendly.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_bonus
    @bonus = Bonus.find(params[:id])
  end
end