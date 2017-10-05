class TasksController < ApplicationController
  before_action :find_level
  before_action :find_game
  before_action :find_teams, only: [:new, :edit]
  before_action :find_task, only: [:edit, :update, :destroy]

  before_action :ensure_author
  before_action :ensure_game_was_not_started, only: [:new, :create, :edit, :update]

  def new
    @task = Task.new
    @task.level = @level
  end

  def create
    @task = Task.new(task_params)
    @task.level = @level
    if @task.save
      redirect_to game_level_path(@game, @level)
    else
      render 'new'
    end
  end

  def edit
    render
  end

  def update
    if @task.update_attributes(task_params)
      redirect_to game_level_path(@level.game, @level)
    else
      render 'edit'
    end
  end

  def destroy
    @task.destroy
    redirect_to game_level_path(@level.game, @level)
  end

  protected

  def task_params
    params.require(:task).permit(:level_id, :text, :team_id)
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_game
    @game = @level.game
  end

  def find_teams
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
  end

  def find_task
    @task = Task.find(params[:id])
  end
end