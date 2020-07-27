class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :find_invitations_for_current_user
  before_action :find_team

  def index
    @games = Game.by(current_user.id).order(starts_at: :desc)
    @game_entries = []
    @teams = []
    @games.each do |game|
      GameEntry.of_game(game.id).with_status('new').each do |entry|
        @game_entries << entry
      end
      GameEntry.of_game(game.id).with_status('accepted').each do |entry|
        @teams << entry.team
      end
    end
    @my_games = Game.all.select { |game| game.created_by?(current_user) }
    render :index, locals: {invitations: @invitations, my_games: @my_games}
  end

  protected

  def find_invitations_for_current_user
    @invitations = Invitation.of(current_user.id) unless current_user.nil?
  end

  def find_team
    @team = current_user.team if current_user.team
  end
end
