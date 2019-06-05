class TeamRequestsController < ApplicationController
  before_action :authenticate_user!

  before_action :find_team_request, only: [:reject, :accept]
  before_action :ensure_recepient, only: [:reject, :accept]

  def new
    @all_users = User.all
    @team_request = TeamRequest.new
    @team_request.user = current_user
  end

  def create
    @team_request = TeamRequest.new(team_request_params)
    @team_request.user = current_user
    if @team_request.save
      redirect_to new_team_request_path, notice: "Капітану команди #{@team_request.team.name} надіслано запит на вступ"
      TeamRequestsMailer.team_request_create(@team_request).deliver_now
    else
      @all_users = User.all
      render 'new'
    end
  end

  def accept
    if @team_request.nil?
      redirect_to dashboard_path, alert: 'Заявка уже прийнята або відхилена'
    else
      add_user_to_team_members
      @team_request.delete
      # reject_rest_of_invitations
      redirect_to team_path(current_user.team)
      TeamRequestsMailer.team_request_accept(@team_request).deliver_now
    end
  end

  def reject
    if @team_request.nil?
      redirect_to dashboard_path, alert: 'Заявка уже прийнята або відхилена'
    else
      @team_request.delete
      redirect_to team_path(current_user.team)
      TeamRequestsMailer.team_request_reject(@team_request).deliver_now
    end
  end

  protected

  def add_user_to_team_members
    team = @team_request.team
    team.members << @team_request.user
  end

  def reject_rest_of_invitations
    Invitation.of(current_user.id).each do |invitation|
      invitation.delete
      InvitationsMailer.invitation_reject(invitation).deliver_now
    end
  end

  def team_request_params
    params.require(:team_request).permit(:team_name)
  end

  def find_team_request
    begin
      @team_request = TeamRequest.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      puts e.message
      puts e.backtrace.inspect
      @team_request = nil
    end
  end

  def ensure_recepient
    unless !@team_request.nil? && current_user.captain_of_team?(@team_request.team)
      fail 'Ви повинні бути капітаном команди для виконання цієї дії'
    end
  end
end
