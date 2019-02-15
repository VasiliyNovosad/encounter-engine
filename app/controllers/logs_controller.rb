class LogsController < ApplicationController
  before_action :authenticate_user!, except: [:show_short_log]
  before_action :find_game
  before_action :ensure_author, only: [:show_level_log, :show_game_log, :show_special_results]
  before_action :ensure_game_finished, only: [:show_live_channel, :show_full_log]
  before_action :find_team, only: [:show_level_log, :show_game_log]
  before_action :find_level, only: [:show_level_log, :show_game_log]

  def index
  end

  def show_special_results
    ships = {
      'A1' => { id: 1185, ship: 'white' },
      'A2' => { id: 1186, ship: 'red' },
      'A3' => { id: 1187, ship: 'red' },
      'A4' => { id: 1188, ship: 'white' },
      'A5' => { id: 1189, ship: 'white' },
      'A6' => { id: 1190, ship: 'white' },
      'A7' => { id: 1191, ship: 'red' },
      'A8' => { id: 1192, ship: 'white' },
      'A9' => { id: 1193, ship: 'white' },
      'A10' => { id: 1194, ship: 'white' },
      'B1' => { id: 1195, ship: 'white' },
      'B2' => { id: 1196, ship: 'white' },
      'B3' => { id: 1197, ship: 'white' },
      'B4' => { id: 1198, ship: 'white' },
      'B5' => { id: 1199, ship: 'white' },
      'B6' => { id: 1200, ship: 'white' },
      'B7' => { id: 1201, ship: 'red' },
      'B8' => { id: 1202, ship: 'white' },
      'B9' => { id: 1203, ship: 'white' },
      'B10' => { id: 1204, ship: 'white' },
      'C1' => { id: 1205, ship: 'white' },
      'C2' => { id: 1206, ship: 'white' },
      'C3' => { id: 1207, ship: 'white' },
      'C4' => { id: 1208, ship: 'red' },
      'C5' => { id: 1209, ship: 'white' },
      'C6' => { id: 1210, ship: 'white' },
      'C7' => { id: 1211, ship: 'white' },
      'C8' => { id: 1212, ship: 'white' },
      'C9' => { id: 1213, ship: 'red' },
      'C10' => { id: 1214, ship: 'white' },
      'D1' => { id: 1215, ship: 'white' },
      'D2' => { id: 1216, ship: 'white' },
      'D3' => { id: 1217, ship: 'white' },
      'D4' => { id: 1218, ship: 'red' },
      'D5' => { id: 1219, ship: 'white' },
      'D6' => { id: 1220, ship: 'white' },
      'D7' => { id: 1221, ship: 'white' },
      'D8' => { id: 1222, ship: 'white' },
      'D9' => { id: 1223, ship: 'white' },
      'D10' => { id: 1224, ship: 'white' },
      'E1' => { id: 1225, ship: 'red' },
      'E2' => { id: 1226, ship: 'white' },
      'E3' => { id: 1227, ship: 'white' },
      'E4' => { id: 1228, ship: 'red' },
      'E5' => { id: 1229, ship: 'white' },
      'E6' => { id: 1230, ship: 'white' },
      'E7' => { id: 1231, ship: 'white' },
      'E8' => { id: 1232, ship: 'white' },
      'E9' => { id: 1233, ship: 'white' },
      'E10' => { id: 1234, ship: 'white' },
      'F1' => { id: 1235, ship: 'white' },
      'F2' => { id: 1236, ship: 'white' },
      'F3' => { id: 1237, ship: 'white' },
      'F4' => { id: 1238, ship: 'white' },
      'F5' => { id: 1239, ship: 'white' },
      'F6' => { id: 1240, ship: 'red' },
      'F7' => { id: 1241, ship: 'red' },
      'F8' => { id: 1242, ship: 'red' },
      'F9' => { id: 1243, ship: 'red' },
      'F10' => { id: 1244, ship: 'white' },
      'G1' => { id: 1245, ship: 'white' },
      'G2' => { id: 1246, ship: 'white' },
      'G3' => { id: 1247, ship: 'white' },
      'G4' => { id: 1248, ship: 'red' },
      'G5' => { id: 1249, ship: 'white' },
      'G6' => { id: 1250, ship: 'white' },
      'G7' => { id: 1251, ship: 'white' },
      'G8' => { id: 1252, ship: 'white' },
      'G9' => { id: 1253, ship: 'white' },
      'G10' => { id: 1254, ship: 'white' },
      'H1' => { id: 1255, ship: 'white' },
      'H2' => { id: 1256, ship: 'red' },
      'H3' => { id: 1257, ship: 'white' },
      'H4' => { id: 1258, ship: 'white' },
      'H5' => { id: 1259, ship: 'white' },
      'H6' => { id: 1260, ship: 'white' },
      'H7' => { id: 1261, ship: 'white' },
      'H8' => { id: 1262, ship: 'white' },
      'H9' => { id: 1263, ship: 'white' },
      'H10' => { id: 1264, ship: 'white' },
      'I1' => { id: 1265, ship: 'white' },
      'I2' => { id: 1266, ship: 'red' },
      'I3' => { id: 1267, ship: 'white' },
      'I4' => { id: 1268, ship: 'white' },
      'I5' => { id: 1269, ship: 'white' },
      'I6' => { id: 1270, ship: 'white' },
      'I7' => { id: 1271, ship: 'white' },
      'I8' => { id: 1272, ship: 'white' },
      'I9' => { id: 1273, ship: 'red' },
      'I10' => { id: 1274, ship: 'red' },
      'J1' => { id: 1275, ship: 'white' },
      'J2' => { id: 1276, ship: 'red' },
      'J3' => { id: 1277, ship: 'white' },
      'J4' => { id: 1278, ship: 'white' },
      'J5' => { id: 1279, ship: 'red' },
      'J6' => { id: 1280, ship: 'white' },
      'J7' => { id: 1281, ship: 'white' },
      'J8' => { id: 1282, ship: 'white' },
      'J9' => { id: 1283, ship: 'white' },
      'J10' => { id: 1284, ship: 'white' }
    }
    game_passings = GamePassing.of_game(@game.id)
    @results = game_passings.map do |game_passing|
      bonuses = game_passing.bonus_ids
      team_field = {}
      ships.keys.each do |cell_name|
        if bonuses.include?(ships[cell_name][:id])
          team_field[cell_name] = ships[cell_name][:ship]
        else
          team_field[cell_name] = 'transparent'
        end
      end
      {
        team_name: game_passing.team_name,
        team_field: team_field
      }
    end

    team_field = {}
    ships.keys.each do |cell_name|
      team_field[cell_name] = ships[cell_name][:ship]
    end
    @results = [{ team_name: 'ORIGINAL', team_field: team_field }] + @results
  end

  def show_live_channel
    require 'ee_strings.rb'
    filter = {}
    filter[:level_id] = params[:level_id].to_i unless params[:level_id].nil? || params[:level_id] == '' || params[:level_id].to_i == 0
    filter[:team_id] = params[:team_id].to_i unless params[:team_id].nil? || params[:team_id] == '' || params[:team_id].to_i == 0
    filter[:user_id] = params[:user_id].to_i unless params[:user_id].nil? || params[:user_id] == '' || params[:user_id].to_i == 0
    logs = Log.of_game(@game.id)
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
    @logs = Log.of_game(@game.id).where(filter).order(time: :desc).page(params[:page] || 1)
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
    @logs = Log.of_game(@game.id).of_team(@team.id).of_level(@level.id).order_by_time
  end

  def show_game_log
    @logs = Log.of_game(@game.id).of_team(@team.id)
  end

  def show_full_log
    require 'ee_strings.rb'
    @logs = Log.of_game(@game.id).order_by_time.preload(:user)
    @levels = Level.of_game(@game.id).includes(questions: :answers, bonuses: :bonus_answers)
    @teams = Team.find_by_sql("select t.* from teams t inner join game_passings gp on t.id = gp.team_id where gp.game_id = #{@game.id}")
  end

  def show_short_log
    if @game.starts_at < DateTime.new(2018, 7, 5, 0, 0, 0)
      logs = Log.of_game(@game.id).order_by_time.preload(:user).to_a
      logs = logs.group_by { |log| [log.team_id, log.level_id]}
      @levels = Level.of_game(@game.id).to_a
      game_passings = GamePassing.of_game(@game.id).preload(:team).to_a
      game_bonuses = GameBonus.of_game(@game.id).select('team_id, level_id, sum(award) as award').group(:level_id, :team_id).to_a
      @teams = game_passings.map(&:team)
      @level_logs = []
      @levels.each do |level|
        @level_logs << @teams.map do |team|
          game_bonus = game_bonuses.select { |bonus| bonus.team_id == team.id && bonus.level_id == level.id }
          team_logs = logs[[team.id, level.id]]
          previous_time = @level_logs.count == 0 ? @game.starts_at : @level_logs.last.select{ |log| log[:team] == team }[0][:time]
          team_log = (!team_logs.nil? && game_passings.select { |gp| gp.team_id == team.id }.first.closed_levels.include?(level.id)) ? team_logs.last : nil
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
    else
      @level_logs = []
      @levels = Level.of_game(@game.id).to_a
      game_passings = GamePassing.of_game(@game.id).preload(:team).to_a
      game_bonuses = GameBonus.of_game(@game.id).select('team_id, level_id, sum(award) as award').group(:level_id, :team_id).to_a
      @teams = game_passings.map(&:team)
      all_closed_levels = ClosedLevel.of_game(@game.id).order(:closed_at).preload(:user).to_a.group_by { |level| level.level_id }
      @levels.each do |level|
        closed_levels_of_level = all_closed_levels[level.id]
        closed_levels_of_level = closed_levels_of_level.group_by { |level| level.team_id} unless closed_levels_of_level.nil?
        @level_logs << @teams.map do |team|
          game_bonus = game_bonuses.select { |bonus| bonus.team_id == team.id && bonus.level_id == level.id }
          closed_level_of_team = closed_levels_of_level.nil? ? nil : closed_levels_of_level[team.id]
          team_log = closed_level_of_team.nil? ? nil : closed_level_of_team[0]
          {
              team: team,
              log: team_log,
              time: team_log.nil? ? Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time : team_log.closed_at,
              result: team_log.nil? ? nil : Time.at(team_log.closed_at - team_log.started_at).utc,
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
