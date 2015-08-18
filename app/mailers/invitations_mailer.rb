class InvitationsMailer < ActionMailer::Base
  default from: "novosadvasiliy@gmail.com",
          template_path: 'mailers/invitations'

  def invitation_create(invitation)
    @invitation = invitation
    mail to: invitation.for_user.email,
         subject: "Запрошення в команду"
  end

  def invitation_reject(invitation)
    @invitation = invitation
    mail to: invitation.to_team.captain.email,
         subject: "Запрошення в команду відхилено"
  end

  def invitation_accept(invitation)
    @invitation = invitation
    mail to: invitation.to_team.captain.email,
         subject: "Запрошення в команду прийнято"
  end

end
