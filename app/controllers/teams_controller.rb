class TeamsController < ApplicationController
  before_action :find_team, only: [:update, :index, :show]
  before_action :ensure_team_member, exclude: [:new, :create]
  before_action :ensure_team_captain, only: [:edit]

  def index
    @teams = Team.all
    render 'show'
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(team_params)
    @team.captain = @current_user
    if @team.save
      redirect_to dashboard_path
    else
      render 'new'
    end
  end

  def edit
    @team = @current_user.team
    render
  end

  def update
    params[:team][:name] = params[:team_old_name] if params[:team][:name].blank?
    if @team.update_attributes(team_params)
      redirect_to team_path(@team)
    else
      render 'edit'
    end
  end

  def show
    @team = Team.find(params[:id])
  end

  def delete_member
    who = User.find(params[:member_id])
    if @current_user.captain? && @current_user.team == who.team && !who.captain?
      who.team = nil
      who.save!
      redirect_to 'teams/edit'
    else
      redirect_to dashboard_path
    end
  end

  def make_member_captain
    who = User.find(params[:member_id])
    if @current_user.captain? && @current_user.team == who.team && !who.captain?
      who_team = @current_user.team
      who_team.captain = who
      who_team.save!
      who.save!
      redirect_to('teams')
    else
      redirect_to(dashboard_path)
    end
  end

  protected

  def team_params
    params.require(:team).permit(:name)
  end

  def find_team
    @team = Team.find(params[:id])
  end

  def ensure_not_member_of_any_team
    current_user.member_of_any_team?
  end
end
