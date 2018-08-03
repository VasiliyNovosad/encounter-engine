class BonusesController < ApplicationController
  before_action :find_game
  before_action :ensure_game_was_not_finished, except: [:show]
  before_action :ensure_author
  before_action :find_level
  before_action :find_bonus, only: [:edit, :update, :move_up, :move_down, :destroy, :copy, :copy_to_sector]
  before_action :find_teams, only: [:new, :edit, :create, :update]

  def new
    @bonus = @level.bonuses.build(name: "Бонус #{@level.bonuses.count + 1}")
    @bonus.bonus_answers.build
  end

  def create
    @bonus = @level.bonuses.build(bonus_params)
    if @bonus.save
      redirect_to game_level_path(@level.game, @level, anchor: "bonus-#{@bonus.id}")
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
    if @bonus.update_attributes(bonus_params)
      redirect_to game_level_path(@bonus.level.game, @bonus.level, anchor: "bonus-#{@bonus.id}")
    else
      render :edit
    end
  end

  def destroy
    @bonus.destroy
    redirect_to game_level_path(@level.game, @level, anchor: "bonuses-block")
  end

  def move_up
    @bonus.move_higher
    redirect_to game_level_path(@level.game, @level, anchor: "bonus-#{@bonus.id}")
  end

  def move_down
    @bonus.move_lower
    redirect_to game_level_path(@level.game, @level, anchor: "bonus-#{@bonus.id}")
  end

  def copy
    @new_bonus = @bonus.dup
    @new_bonus.name = "Бонус #{@level.bonuses.count + 1}"
    @new_bonus.set_list_position(@level.bonuses.count + 1)
    @bonus.bonus_answers.each do |answer|
      new_answer = answer.dup
      new_answer.bonus_id = nil
      @new_bonus.bonus_answers << new_answer
    end
    if @new_bonus.save
      redirect_to game_level_path(@level.game, @level, anchor: "bonus-#{@new_bonus.id}")
    else
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@level.game, @level, anchor: "bonus-#{@bonus.id}")
    end
  end

  def copy_to_sector
    @new_question = @level.questions.build(name: "Сектор #{@level.questions.count + 1}")
    @new_question.set_list_position(@level.questions.count + 1)
    @bonus.bonus_answers.each do |answer|
      @new_question.answers.build(value: answer.value, team_id: answer.team_id)
    end
    if @new_question.save
      redirect_to game_level_path(@level.game, @level, anchor: "question-#{@new_question.id}")
    else
      p @new_question.errors
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_level_path(@level.game, @level, anchor: "bonus-#{@bonus.id}")
    end
  end

  protected

  def bonus_params
    params.require(:bonus).permit(
        :name, :task, :help, :award_time, :correct_answer, :team_id,
        :is_absolute_limited, :valid_from, :valid_to, :is_delayed,
        :delay_for, :is_relative_limited, :valid_for,
        bonus_answers_attributes: [:id, :value, :team_id, :_destroy])
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

  def find_teams
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
  end
end