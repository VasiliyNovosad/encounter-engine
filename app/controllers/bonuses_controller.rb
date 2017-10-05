class BonusesController < ApplicationController
  before_action :find_game
  before_action :ensure_author
  before_action :find_level
  before_action :find_bonus, only: [:edit, :update, :move_up, :move_down, :destroy]
  before_action :find_teams, only: [:new, :edit]

  def new
    @bonus = Bonus.new
    @bonus.level = @level
  end

  def create
    @bonus = Bonus.new(bonus_params)
    @bonus.level = @level
    if @bonus.save
      @answer = @bonus.bonus_answers.first
      if @answer.save
        redirect_to game_level_path(@level.game, @level)
      else
        @bonus.destroy
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
    if @bonus.update_attributes(bonus_params)
      redirect_to game_level_bonus_path(@bonus.level.game, @bonus.level, @bonus)
    else
      render 'edit'
    end
  end

  def destroy
    @bonus.bonus_answers.each { |answer| answer.destroy }
    @bonus.destroy
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
    params.require(:bonus).permit(:name, :task, :help, :award_time, :correct_answer, :team_id)
  end

  def find_game
    @game = Game.find(params[:game_id])
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