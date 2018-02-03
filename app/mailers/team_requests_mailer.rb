class TeamRequestsMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  default from: "quest.racing.lutsk@gmail.com",
          template_path: 'mailers/team_requests'

  def team_request_create(team_request)
    @team_request = team_request
    mail to: team_request.team.captain.email,
         body: "Гравець #{team_request.user.nickname} хоче приєднатись до Вашої команди #{link_to(team_request.team.name, team_url(team_request.team))}",
         content_type: "text/plain",
         subject: "Запрошення в команду"
  end

  def team_request_reject(team_request)
    @team_request = team_request
    mail to: team_request.team.captain.email,
         body: "Вас не прийнято до складу команди #{link_to(team_request.team.name, team_url(team_request.team))}",
         content_type: "text/plain",
         subject: "Запит на вступ до складу команди відхилено"
  end

  def team_request_accept(team_request)
    @team_request = team_request
    mail to: team_request.team.captain.email,
         body: "Вас прийнято до складу команди #{link_to(team_request.team.name, team_url(team_request.team))}",
         content_type: "text/plain",
         subject: "Запит на вступ до складу команди прийнято"
  end
end
