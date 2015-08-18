class InvitationsController < ApplicationController
  autocomplete :user, :nickname
  before_filter :ensure_authenticated

  #before_action :build_invitation, :only => [:new, :create]
  before_action :ensure_team_captain, :only => [:new, :create]

  before_action :find_invitation, :only => [:reject, :accept]
  before_action :ensure_recepient, :only => [:reject, :accept]

  def new
    @all_users = User.all
    @invitation = Invitation.new
    @invitation.to_team = @current_user.team
  end

  def create
    @invitation = Invitation.create(invitation_params)
    @invitation.to_team = @current_user.team
    if @invitation.save
      redirect_to new_invitation_path, :message => "Користувачу #{@invitation.recepient_nickname} надіслано запрошення"
      InvitationsMailer.invitation_create(@invitation).deliver#send_invitation_notification(@invitation)
    else
      @all_users = User.all
      render "new"
    end
  end

  def accept
    add_user_to_team_members
    @invitation.delete
    #send_accept_notification(@invitation)
    reject_rest_of_invitations    
    redirect_to dashboard_path
    InvitationsMailer.invitation_accept(@invitation).deliver
  end

  def reject    
    @invitation.delete
    #send_reject_notification(@invitation)
    redirect_to dashboard_path
    InvitationsMailer.invitation_reject(@invitation).deliver
  end

protected

  def add_user_to_team_members
    team = @invitation.to_team
    team.members << @current_user
  end
  
  def reject_rest_of_invitations
    Invitation.for(@current_user).each do |invitation|
      invitation.delete
      InvitationsMailer.invitation_reject(invitation).deliver
      #send_reject_notification(invitation)
    end
  end

  def invitation_params
    params.require(:invitation).permit!
  end

  def build_invitation
    @invitation = Invitation.new(invitation_params)
    @invitation.to_team = @current_user.team
  end

  def find_invitation    
    @invitation = Invitation.find(params[:id])
  end

  def ensure_recepient
    unless @current_user.id == @invitation.for_user.id
      raise "Ви повинні бути отримувачем запрошення для виконання цієї дії"
    end
  end
end
