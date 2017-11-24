class LogsController < ApplicationController
  before_action :authenticate_user!, except: [:show_short_log]
  before_action :find_game
  before_action :ensure_author, only: [:show_live_channel, :show_level_log, :show_game_log]
  before_action :ensure_game_finished, only: [:show_full_log]
  before_action :find_team, only: [:show_level_log, :show_game_log]
  before_action :find_level, only: [:show_level_log, :show_game_log]

  def index
    render
  end

  def show_live_channel
    @logs = Log.of_game(@game)
    render
  end

  def show_level_log
    @logs = Log.of_game(@game).of_team(@team).of_level(@level)
    render
  end

  def show_game_log
    @logs = Log.of_game(@game).of_team(@team)
    render
  end

  def show_full_log
    @logs = Log.of_game(@game)
    @levels = Level.of_game(@game)
    @teams = Team.find_by_sql("select t.* from teams t inner join game_passings gp on t.id = gp.team_id where gp.game_id = #{@game.id}")
    render
  end

  def show_short_log
    logs = Log.of_game(@game)
    @levels = Level.of_game(@game)
    @teams = Team.find_by_sql("select t.* from teams t inner join game_passings gp on t.id = gp.team_id where gp.game_id = #{@game.id}")
    @level_logs = []
    @levels.each do |level|
      @level_logs << @teams.map do |team|
        team_logs = logs.of_team(team).of_level(level)
        previous_time = @level_logs.count == 0 ? @game.starts_at : @level_logs.last.select{ |log| log[:team] == team }[0][:time]
        team_log = (team_logs.count > 0 && GamePassing.of(team, @game).closed_levels.include?(level.id)) ? team_logs.last : nil # && GamePassing.of(team, @game).closed_levels.include?(level.id)
        {
            team: team,
            log: team_log,
            time: team_log.nil? ? Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time : team_log.time,
            result: team_log.nil? ? nil : Time.at(team_log.time - previous_time).utc
        }
      end.sort_by { |a| a[:time] }
    end

    results = GamePassing.where(game_id: @game.id).to_a
    results = results.map do |result|
      {
        team: result.team,
        levels: result.closed_levels.count,
        bonuses: result.sum_bonuses,
        time: result.finished_at || result.current_level_entered_at
      }
    end
    results = results.sort_by do |a|
      [-a[:levels], a[:time]]
    end
    @level_logs << results
    results = results.map do |result|
      {
        team: result[:team],
        levels: result[:levels],
        time: (result[:time] - result[:bonuses])
      }
    end
    results = results.sort_by do |a|
      [-a[:levels], a[:time]]
    end
    @level_logs << results
    render
  end

  protected

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_team
    @team = Team.find(params[:team_id])
  end

  def find_level
    @level = @team.current_level_in(@game)
  end

  def ensure_game_finished
    if @game.author_finished_at.nil? && !current_user.author_of?(@game)
      redirect_to root_path, alert: 'Заборонено до закриття гри!'
    end
  end
end
