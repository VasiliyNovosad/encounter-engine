class InvitationsController < ApplicationController
  before_action :authenticate_user!

  before_action :ensure_team_captain, only: [:new, :create]

  before_action :find_invitation, only: [:reject, :accept]
  before_action :ensure_recepient, only: [:reject, :accept]

  def new
    @all_users = User.all
    @invitation = Invitation.new
    @invitation.to_team = current_user.team
  end

  def create
    @invitation = Invitation.new(invitation_params)
    @invitation.to_team = current_user.team
    if @invitation.save
      redirect_to new_invitation_path, notice: "Користувачу #{@invitation.for_user.nickname} надіслано запрошення"
      InvitationsMailer.invitation_create(@invitation).deliver_now
    else
      @all_users = User.all
      render 'new'
    end
  end

  def accept
    add_user_to_team_members
    @invitation.delete
    # reject_rest_of_invitations
    redirect_to dashboard_path
    InvitationsMailer.invitation_accept(@invitation).deliver_now
  end

  def reject
    @invitation.delete
    redirect_to dashboard_path
    InvitationsMailer.invitation_reject(@invitation).deliver_now
  end

  protected

  def add_user_to_team_members
    team = @invitation.to_team
    team.members << current_user
  end

  def reject_rest_of_invitations
    Invitation.of(current_user.id).each do |invitation|
      invitation.delete
      InvitationsMailer.invitation_reject(invitation).deliver_now
    end
  end

  def invitation_params
    params.require(:invitation).permit(:recepient_nickname)
  end

  def build_invitation
    @invitation = Invitation.new(invitation_params)
    @invitation.to_team = current_user.team
  end

  def find_invitation
    @invitation = Invitation.find(params[:id])
  end

  def ensure_recepient
    unless current_user.id == @invitation.for_user.id
      fail 'Ви повинні бути отримувачем запрошення для виконання цієї дії'
    end
  end
end
