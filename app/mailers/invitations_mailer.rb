class InvitationsMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  default from: 'quest.racing.lutsk@gmail.com',
          template_path: 'mailers/invitations'

  def invitation_create(invitation)
    @invitation = invitation
    team = invitation.to_team
    mail to: invitation.for_user.email,
         body: "Вас запрошено вступити в команду #{team.name}: #{team_url(team)}",
         content_type: 'text/plain',
         subject: 'Запрошення в команду'
  end

  def invitation_reject(invitation)
    @invitation = invitation
    mail to: invitation.to_team.captain.email,
         body: "Користувач #{invitation.for_user.nickname} відмовився від запрошення",
         content_type: 'text/plain',
         subject: 'Запрошення в команду відхилено'
  end

  def invitation_accept(invitation)
    @invitation = invitation
    mail to: invitation.to_team.captain.email,
         body: "Користувач #{invitation.for_user.nickname} прийняв Ваше запрошення",
         content_type: 'text/plain',
         subject: 'Запрошення в команду прийнято'
  end

end
