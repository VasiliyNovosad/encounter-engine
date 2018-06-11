class BonusesController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :find_level
  before_action :find_bonus, only: [:edit, :update, :move_up, :move_down, :destroy]
  before_action :find_teams, only: [:new, :edit, :create, :update]

  def new
    @bonus = @level.bonuses.build(name: "Бонус #{@level.bonuses.count + 1}")
  end

  def create
    @bonus = @level.questions.build(bonus_params)
    if @bonus.save
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
    if @bonus.update_attributes(bonus_params)
      redirect_to game_level_bonus_path(@bonus.level.game, @bonus.level, @bonus)
    else
      render :edit
    end
  end

  def destroy
    @bonus.destroy
    redirect_to game_level_path(@level.game, @level)
  end

  def move_up
    @bonus.move_higher
    redirect_to game_level_path(@level.game, @level)
  end

  def move_down
    @bonus.move_lower
    redirect_to game_level_path(@level.game, @level)
  end

  protected

  # t.integer :level_id
  # t.string :name
  # t.string :task
  # t.string :help
  # t.integer :team_id
  # t.integer :award_time
  # t.integer :position
  def bonus_params
    params.require(:bonus).permit(
        :name, :task, :help, :award_time, :correct_answer, :team_id,
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