class LogsController < ApplicationController
  before_action :authenticate_user!, except: [:show_short_log]
  before_action :find_game
  before_action :ensure_author, only: [:show_level_log, :show_game_log]
  before_action :ensure_game_finished, only: [:show_live_channel, :show_full_log]
  before_action :find_team, only: [:show_level_log, :show_game_log]
  before_action :find_level, only: [:show_level_log, :show_game_log]

  def index
  end

  def show_live_channel
    require 'ee_strings.rb'
    filter = {}
    filter[:level_id] = params[:level_id].to_i unless params[:level_id].nil? || params[:level_id] == '' || params[:level_id].to_i == 0
    filter[:team_id] = params[:team_id].to_i unless params[:team_id].nil? || params[:team_id] == '' || params[:team_id].to_i == 0
    filter[:user_id] = params[:user_id].to_i unless params[:user_id].nil? || params[:user_id] == '' || params[:user_id].to_i == 0
    logs = Log.of_game(@game)
    @log_levels = Level.where(id: logs.map(&:level_id).uniq).order(:position)
    @level_id = params[:level_id].to_i
    @log_teams = Team.where(id: logs.map(&:team_id).uniq).order(:name).map{ |team| [team.name, team.id] }
    @team_id = params[:team_id].to_i
    @log_users = User.where(id: logs.map(&:user_id).uniq).order(:nickname).map{ |user| [user.nickname, user.id] }
    users = {}
    @log_users.each { |user| users[user[1]] = user[0] }
    levels = {}
    @log_levels.each { |level| levels[level.id] = "#{level.position}. #{level.name}" }
    @user_id = params[:user_id].to_i
    @logs = Log.of_game(@game).where(filter).order(time: :desc).page(params[:page] || 1)
    @all_logs = []

    if @game.starts_at < DateTime.new(2018,7,5,0,0,0)
      logs_levels = Level.where(id: @logs.map(&:level_id).uniq).includes(questions: :answers, bonuses: :bonus_answers)
      correct_answers = []
      correct_bonus_answers = []
      logs_levels.each do |level|
        level.questions.each do |question|
          question.answers.each { |answer| correct_answers << { level_id: level.id, team_id: answer.team_id, value: answer.value.strip.downcase_utf8_cyr} }
        end
        level.bonuses.each do |bonus|
          bonus.bonus_answers.each { |answer| correct_bonus_answers << { level_id: level.id, team_id: answer.team_id, value: answer.value.strip.downcase_utf8_cyr} }
        end
      end

      @logs.each do |log|
        correct_team_answers = correct_answers.select { |answer| (answer[:team_id] == log.team_id || answer[:team_id].nil?) && answer[:level_id] == log.level_id && answer[:value] == log.answer.strip.downcase_utf8_cyr }
        correct_team_bonus_answers = correct_bonus_answers.select { |answer| (answer[:team_id] == log.team_id || answer[:team_id].nil?) && answer[:level_id] == log.level_id && answer[:value] == log.answer.strip.downcase_utf8_cyr }
        if correct_team_answers.length > 0 && correct_team_bonus_answers.length > 0
          @all_logs << {
            time: log.time,
            team: log.team,
            level: levels[log.level_id],
            answer: log.answer,
            correct_answer: true,
            correct_bonus_answer: false,
            user: log.user_id.nil? ? '' : users[log.user_id]
          }
          @all_logs << {
              time: log.time,
              team: log.team,
              level: levels[log.level_id],
              answer: log.answer,
              correct_answer: false,
              correct_bonus_answer: true,
              user: log.user_id.nil? ? '' : users[log.user_id]
          }
        elsif correct_team_answers.length > 0
          @all_logs << {
              time: log.time,
              team: log.team,
              level: levels[log.level_id],
              answer: log.answer,
              correct_answer: true,
              correct_bonus_answer: false,
              user: log.user_id.nil? ? '' : users[log.user_id]
          }
        elsif correct_team_bonus_answers.length > 0
          @all_logs << {
              time: log.time,
              team: log.team,
              level: levels[log.level_id],
              answer: log.answer,
              correct_answer: false,
              correct_bonus_answer: true,
              user: log.user_id.nil? ? '' : users[log.user_id]
          }
        else
          @all_logs << {
              time: log.time,
              team: log.team,
              level: levels[log.level_id],
              answer: log.answer,
              correct_answer: false,
              correct_bonus_answer: false,
              user: log.user_id.nil? ? '' : users[log.user_id]
          }
        end
      end
    else
      @logs.each do |log|
        @all_logs << {
            time: log.time,
            team: log.team,
            level: levels[log.level_id],
            answer: log.answer,
            correct_answer: (log.answer_type == 1 || log.answer_type == 3),
            correct_bonus_answer: (log.answer_type == 2),
            user: log.user_id.nil? ? '' : users[log.user_id]
        }
      end
    end
    @all_logs
  end

  def show_level_log
    @logs = Log.of_game(@game).of_team(@team).of_level(@level).order_by_time
  end

  def show_game_log
    @logs = Log.of_game(@game).of_team(@team)
  end

  def show_full_log
    require 'ee_strings.rb'
    @logs = Log.of_game(@game).order_by_time.preload(:user)
    @levels = Level.of_game(@game).includes(questions: :answers, bonuses: :bonus_answers)
    @teams = Team.find_by_sql("select t.* from teams t inner join game_passings gp on t.id = gp.team_id where gp.game_id = #{@game.id}")
  end

  def show_short_log
    logs = Log.of_game(@game).order_by_time.preload(:user).to_a
    @levels = Level.of_game(@game).to_a
    game_passings = GamePassing.of_game(@game).preload(:team).to_a
    game_bonuses = GameBonus.of_game(@game).select('team_id, level_id, sum(award) as award').group(:level_id, :team_id)
    @teams = game_passings.map(&:team)
    @level_logs = []
    @levels.each do |level|
      @level_logs << @teams.map do |team|
        game_bonus = game_bonuses.select { |bonus| bonus.team_id == team.id && bonus.level_id == level.id }
        team_logs = logs.select { |log| log.team_id == team.id && log.level_id == level.id }
        previous_time = @level_logs.count == 0 ? @game.starts_at : @level_logs.last.select{ |log| log[:team] == team }[0][:time]
        team_log = (team_logs.count > 0 && game_passings.select { |gp| gp.team_id == team.id }.first.closed_levels.include?(level.id)) ? team_logs.last : nil
        {
            team: team,
            log: team_log,
            time: team_log.nil? ? Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time : team_log.time,
            result: team_log.nil? ? nil : Time.at(team_log.time - previous_time).utc,
            bonus: game_bonus.empty? ? 0 : game_bonus[0].award
        }
      end.sort_by { |a| a[:time] }
    end

    results = game_passings.map do |result|
      game_bonus = game_bonuses.select { |bonus| bonus.team_id == result.team.id }.inject(0) { |sum, bonus| sum + bonus.award }
      {
        team: result.team,
        levels: result.closed_levels.count,
        bonuses: (result.sum_bonuses || 0) + game_bonus,
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
