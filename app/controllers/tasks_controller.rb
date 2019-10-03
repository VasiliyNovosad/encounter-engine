class TasksController < ApplicationController
  before_action :find_level
  before_action :find_game
  before_action :ensure_game_was_not_finished
  before_action :find_teams, only: [:new, :edit, :create, :update]
  before_action :find_task, only: [:edit, :update, :destroy]

  before_action :ensure_author
  before_action :ensure_game_was_not_started, only: [:new, :create, :edit, :update]

  def new
    @task = @level.tasks.build
  end

  def create
    @task = @level.tasks.build(task_params)
    if @task.save
      redirect_to game_level_path(@game, @level, anchor: "task-#{@task.id}")
    else
      render 'new'
    end
  end

  def edit
    render
  end

  def update
    if @task.update_attributes(task_params)
      redirect_to game_level_path(@level.game, @level, anchor: "task-#{@task.id}")
    else
      render 'edit'
    end
  end

  def destroy
    @task.destroy
    redirect_to game_level_path(@level.game, @level, anchor: "tasks-block")
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

  def find_task
    @task = Task.find(params[:id])
  end
end