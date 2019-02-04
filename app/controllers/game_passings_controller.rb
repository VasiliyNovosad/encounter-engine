require 'ee_strings.rb'

class GamePassingsController < ApplicationController
  include GamePassingsHelper

  before_action :authenticate_user!, except: [:index, :show_results]
  before_action :find_game, except: [:exit_game]
  before_action :find_game_by_id, only: [:exit_game]
  before_action :ensure_user_has_team, only: [:show_current_level, :get_current_level_tip, :post_answer, :autocomplete_level, :penalty_hint, :get_current_level_bonus, :miss_current_level_bonus]
  before_action :find_team, except: [:show_results, :index]
  before_action :find_team_id, only: [:show_current_level, :get_current_level_tip, :post_answer, :autocomplete_level, :penalty_hint, :get_current_level_bonus, :miss_current_level_bonus]
  before_action :ensure_team_is_accepted, except: [:show_results, :index]
  before_action :ensure_game_is_started
  before_action :ensure_not_author_of_the_game, except: [:index, :show_results]
  before_action :find_or_create_game_passing, except: [:show_results, :index]
  before_action :ensure_team_captain, only: [:exit_game]
  before_action :ensure_not_finished, except: [:index, :show_results]
  before_action :author_finished_at, except: [:index, :show_results]
  before_action :ensure_team_member, except: [:index, :show_results]
  before_action :ensure_author, only: [:index]

  def show_current_level
    time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    respond_to do |format|
      if @game_passing.finished_at.nil? && !(@game.game_type == 'panic' && (@game.starts_at + @game.duration * 60) < time)
        @level = if @game.game_type == 'panic'
                   params[:level] ? @game.levels.where(position: params[:level]).first : @game.levels.first
                 else
                   @game_passing.current_level
                 end
        @entered_all_answers = get_uniq_level_codes(@level)
        @bonuses = get_answered_bonuses(@level)
        @sectors = get_answered_questions(@level)
        @penalty_hints = get_penalty_hints(@level)
        @upcoming_hints = @game_passing.upcoming_hints(@team_id, @level)
        @hints_to_show = @game_passing.hints_to_show(@team_id, @level)
        format.html do
          render layout: 'in_game', locals: {
              game_passing: @game_passing,
              game: @game,
              team_id: @team_id,
              level: @level,
              entered_all_answers: @entered_all_answers,
              bonuses: @bonuses,
              sectors: @sectors,
              penalty_hints: @penalty_hints,
              upcoming_hints: @upcoming_hints,
              hints_to_show: @hints_to_show,
              answer: @answer
          }
        end
        format.json do
          level_position = @game.game_type == 'selected' ? @game_passing.current_level_position(@team_id) : @level.position
          all_sectors = @level.team_questions(@team_id)
          sectors_count = all_sectors.count
          level_time =  if @game.game_type == 'panic'
                          (@level.complete_later || 0).zero? ? @game.duration * 60 : @level.complete_later
                        else
                          @level.complete_later || 0
                        end
          level_start = level_position == 1 || @game.game_type == 'panic' ? @game.starts_at : @game_passing.current_level_entered_at
          hint_num = 0
          current_level_json = {
              game: {id: @game.id, name: @game.name, levels_count: @game.levels.count, game_type: @game.game_type},
              team: {id: @team.id, name: @team.name},
              level: {
                  id: @level.id,
                  name: @level.name,
                  position: level_position,
                  autocomplete_time: level_time,
                  left_time: level_time == 0 ? 0 : (level_start - time).to_i + level_time,
                  sectors_count: sectors_count,
                  sectors_need: @level.sectors_for_close.zero? ? sectors_count : @level.sectors_for_close,
                  sectors_closed: @game.game_type == 'panic' ? @game_passing.questions.count : (@game_passing.question_ids.to_set & all_sectors.map(&:id).to_set).count,
                  tasks: @level.team_tasks(@team_id).map { |task| {id: task.id, text: task.text} },
                  messages: @level.messages.map { |message| { user: message.user.nickname, text: message.text} },
                  hints: @hints_to_show.map do |hint|
                    hint_num += 1
                    {
                      id: hint.id,
                      number: hint_num,
                      text: hint.text,
                      time_to_hint: 0
                    }
                  end + @upcoming_hints.map do |hint|
                    hint_num += 1
                    {
                      id: hint.id,
                      number: hint_num,
                      text: '',
                      time_to_hint: hint.available_in(level_start)
                    }
                  end,
                  penalty_hints: @penalty_hints.map do |hint|
                    {
                      id: hint[:id],
                      name: hint[:name],
                      penalty: hint[:penalty] || 0,
                      used: hint[:used],
                      text: hint[:used] ? hint[:text] : ''
                    }
                  end,
                  sectors: @sectors.map do |sector|
                    {
                      id: sector[:id],
                      position: sector[:position],
                      name: sector[:name],
                      answered: sector[:answered],
                      answer: sector[:answered] ? sector[:answer] : ''
                    }
                  end,
                  bonuses: @bonuses.map do |bonus|
                    {
                        id: bonus[:id],
                        name: bonus[:name],
                        answered: bonus[:answered],
                        help: bonus[:answered] ? bonus[:help] : '',
                        award: bonus[:answered] ? bonus[:award] : 0,
                        answer: bonus[:answered] ? bonus[:value] : '',
                        missed: bonus[:missed],
                        delayed: bonus[:delayed] && !bonus[:missed],
                        delay_for: bonus[:delayed] && !bonus[:missed] ? bonus[:delay_for] : 0,
                        limited: bonus[:limited] && !bonus[:missed] && !bonus[:answered] && (!bonus[:delayed] || bonus[:delay_for].zero?),
                        valid_for: bonus[:limited] && !bonus[:answered] && !bonus[:missed] ? bonus[:valid_for] : 0,
                        task: bonus[:answered] || bonus[:missed] || bonus[:delayed] ? '' : bonus[:task]
                    }
                  end
              }
          }

          render json: current_level_json
        end
      else
        format.html { redirect_to game_passings_show_results_url(game_id: @game.id) }
        format.json { render json: {status: 'ok', message: 'game finished'} }
      end
    end
  end

  def index
    @game_passings = GamePassing.of_game(@game.id)
    render
  end

  def get_current_level_tip
    level_id = params[:level_id]
    level = Level.find(level_id)
    upcoming_hints_count = @game_passing.upcoming_hints(@team_id, level).count
    hints_to_show = @game_passing.hints_to_show(@team_id, level)
    hint_to_show_count = hints_to_show.count
    last_hint = hints_to_show.last

    render json: { hint_num: hint_to_show_count,
                   hint_text: (hint_to_show_count == 0 ? '' : last_hint.text.html_safe),
                   hint_id: (hint_to_show_count == 0 ? nil : last_hint.id),
                   hint_count: hint_to_show_count + upcoming_hints_count
                 }
  end

  def get_current_level_bonus
    level_id = params[:level_id]
    level = Level.find(level_id)
    bonus_id = params[:bonus_id]
    bonus = level.bonuses.find(bonus_id)
    current_level_entered_at = level.position == 1 || @game_passing.game.game_type == 'panic' ? level.game.starts_at : @game_passing.current_level_entered_at
    current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    if !bonus.nil? && !bonus.is_delayed_now?(current_level_entered_at, current_time)
      render json: {
        bonus_num: bonus.position,
        bonus_name: bonus.name,
        bonus_task: bonus.task,
        bonus_id: bonus.id,
        bonus_limited: bonus.is_limited_now?(current_level_entered_at, current_time),
        bonus_valid_for: bonus.time_to_miss(current_level_entered_at, current_time)
      }
    else
      render json: {}
    end
  end

  def miss_current_level_bonus
    level_id = params[:level_id]
    level = Level.find(level_id)
    bonus_id = params[:bonus_id]
    bonus = level.bonuses.find(bonus_id)
    @game_passing.miss_bonus!(level_id, bonus.id)

    render json: {bonus_id: bonus.id, bonus_name: bonus.name}
  end

  def post_answer
    time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    if @game_passing.finished? ||
       @game.game_type == 'panic' &&
       @game.starts_at + 60 * @game.duration < time
      respond_to do |format|
        # format.html { redirect_to game_passings_show_results_url(game_id: @game.id) }
        format.js
      end
    else

      level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
      if (level == @game_passing.current_level || @game.game_type == 'panic') && !level.complete_later.nil? && level.complete_later > 0
        begin
          time_start = level.position == 1 || @game.game_type == 'panic' ? @game.starts_at : @game_passing.current_level_entered_at
          time_finish = time_start + level.complete_later
          if time > time_finish
            save_log(level, time_finish, 3)
            @game_passing.autocomplete_level!(level, @team_id, time_start, time_finish, current_user.id)
            respond_to do |format|
              # format.html do
              #   redirect_to 'show_current_level'
              # end
              format.js
            end
          end
        rescue

        end
      end

      @answer = params[:answer].strip
      if @answer == ''
        respond_to do |format|
          # format.html do
          #   redirect_to 'show_current_level'
          # end
          format.js
        end
      else
        @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
        answer_was_correct = @game_passing.check_answer!(@answer, @level, @team_id, time, current_user)
        @answer_was_correct = answer_was_correct[:correct] || answer_was_correct[:bonus]
        answered = []
        if @answer_was_correct
          if answer_was_correct[:correct]
            save_log(@level, time, 1) if @game_passing.current_level.id || @game.game_type == 'panic'
            answered.push(
              {
                  time: time.strftime("%H:%M:%S"),
                  user: current_user.nickname,
                  answer: "<span class=\"right_code\">#{@answer}</span>"
              })
          end
          if answer_was_correct[:bonus]
            save_log(@level, time, 2) if @game_passing.current_level.id || @game.game_type == 'panic'
            answered.push(
                {
                    time: time.strftime("%H:%M:%S"),
                    user: current_user.nickname,
                    answer: "<span class=\"bonus\">#{@answer}</span>"
                }
            )
          end
        else
          save_log(@level, time, 0) if @game_passing.current_level.id || @game.game_type == 'panic'
          answered.push(
              {
                  time: time.strftime("%H:%M:%S"),
                  user: current_user.nickname,
                  answer: @answer
              }
          )
        end
        if @game_passing.finished?
          PrivatePub.publish_to "/game_passings/#{@game_passing.id}/#{@level.id}", url: '/game_passings/show_results'
          respond_to do |format|
            # format.html { redirect_to game_passings_show_results_url(game_id: @game.id) }
            format.js
          end
        else
          respond_to do |format|
            # format.html do
            #   redirect_to 'show_current_level'
            # end
            format.js do
              PrivatePub.publish_to "/game_passings/#{@game_passing.id}/#{@level.id}/answers", {
                  answers: answered,
                  sectors: answer_was_correct[:sectors],
                  bonuses: answer_was_correct[:bonuses],
                  needed: answer_was_correct[:needed],
                  closed: answer_was_correct[:closed]
              }
              if @game.game_type == 'panic' && !answer_was_correct[:bonuses].nil?
                levels = Hash.new { |h, k| h[k] = [] }
                answer_was_correct[:bonuses].each do |bonus|
                  Bonus.joins(:levels).where(id: bonus[:id]).pluck('levels.id').each do |level_id|
                    levels[level_id].push(bonus.merge({level_id: level_id})) unless level_id == bonus[:level_id]
                  end
                end
                levels.each do |k, v|
                  PrivatePub.publish_to "/game_passings/#{@game_passing.id}/#{k}/answers", {
                      answers: [],
                      sectors: [],
                      bonuses: v,
                      needed: [],
                      closed: []
                  }
                end
              end
            end
          end
        end
      end
    end
  end

  def show_results
    game_bonuses = GameBonus.of_game(@game.id).select("team_id, sum(award) as sum_bonuses").group(:team_id).to_a
    game_passings = GamePassing.of_game(@game.id).includes(:team)

    if @game.game_type == 'panic'
      game_finished_at = @game.starts_at + @game.duration * 60
      @game_passings = game_passings.map do |game_passing|
        team_bonus = game_bonuses.select{ |bonus| bonus.team_id == game_passing.team_id}
        {
            team_id: game_passing.team.id,
            team_name: game_passing.team.name,
            finished_at: game_passing.finished_at || game_finished_at,
            closed_levels: game_passing.closed_levels.count,
            sum_bonuses: (game_passing.sum_bonuses || 0) + (team_bonus.empty? ? 0 : team_bonus[0].sum_bonuses)
        }
      end.sort do |a, b|
        (a[:finished_at] - a[:sum_bonuses]) <=> (b[:finished_at] - b[:sum_bonuses])
      end
    else
      current_time = Time.now
      @game_passings = game_passings.map do |game_passing|
        team_bonus = game_bonuses.select{ |bonus| bonus.team_id == game_passing.team_id}
        {
            team_id: game_passing.team.id,
            team_name: game_passing.team.name,
            finished_at: game_passing.finished_at,
            closed_levels: game_passing.closed_levels.count,
            sum_bonuses: (game_passing.sum_bonuses || 0) + (team_bonus.empty? ? 0 : team_bonus[0].sum_bonuses),
            exited: game_passing.exited?
        }
      end.sort_by do |v|
        [-v[:closed_levels], (v[:finished_at] || current_time) - v[:sum_bonuses]]
      end
    end
  end

  def exit_game
    @game_passing.exit!
    redirect_to game_passings_show_results_url(game_id: @game.id)
  end

  def autocomplete_level
    time = Time.now
    level_id = params[:level]
    unless @game_passing.finished?
      level = Level.find(level_id)
      @game_passing = GamePassing.of(@team.id, @game.id)
      if level == @game_passing.current_level || @game.game_type == 'panic'
        begin
          time_start = level.position == 1 || @game.game_type == 'panic' ? @game.starts_at : @game_passing.current_level_entered_at
          time_finish = time_start + level.complete_later
          if time_finish < time
            save_log(level, time_finish, 3)
            @game_passing.autocomplete_level!(level, @team_id, time_start, time_finish, current_user.id)
          end
        rescue => e
          raise e
        end
      end
    end
    render json: { result: true }.to_json
  end

  def use_penalty_hint
    level_id = params[:level_id]
    penalty_hint_id = params[:hint_id]
    @game_passing.use_penalty_hint!(level_id, penalty_hint_id, current_user.id)
    respond_to do |format|
      format.js
    end
  end

  def show_penalty_hint
    level_id = params[:level_id]
    level = Level.find(level_id)
    penalty_hint_id = params[:hint_id]
    penalty_hint = level.penalty_hints.find(penalty_hint_id)
    current_level_entered_at = level.position == 1 || @game_passing.game.game_type == 'panic' ? level.game.starts_at : @game_passing.current_level_entered_at
    current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    if !penalty_hint.nil? && (!penalty_hint.is_delayed? || (penalty_hint.time_to_delay(current_level_entered_at, current_time) || 0) <= 0)
      render json: {
          hint_name: penalty_hint.name,
          hint_id: penalty_hint.id,
          hint_penalty: seconds_to_string(penalty_hint.penalty || 0)
      }
    else
      render json: {}
    end
  end

  protected

  def save_log(level = @game_passing.current_level, time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time, answer_type = 0)
    Log.create!(
      game_id: @game.id,
      level: level.name,
      level_id: level.id,
      team: @team.name,
      team_id: @team.id,
      time: time,
      answer: @answer || 'timeout',
      user: current_user,
      answer_type: answer_type
    )
  end

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_game_by_id
    @game = Game.find(params[:id])
  end

  def find_or_create_game_passing
    @game_passing = GamePassing.of(@team.id, @game.id)

    if @game_passing.nil?
      @game_passing = GamePassing.create! team: @team,
                                          game: @game,
                                          current_level: @game.game_type == 'selected' ? Level.find_by_id(LevelOrder.of(@game.id, @team_id).first.level_id) : @game.levels.first
    end
  end

  def find_team
    @team = @game.team_type == 'multy' ? current_user.team : current_user.single_team
    if @game.is_testing? && !@game.tested_team_id.nil?
      @team = Team.find(@game.tested_team_id)
    end
  end

  def find_team_id
    @team_id = @game.team_type == 'multy' ? current_user.team_id : current_user.single_team_id
    if @game.is_testing? && !@game.tested_team_id.nil?
      @team_id = @game.tested_team_id
    end
  end

  def ensure_game_is_started
    unless (@game.is_testing? ? @game.test_date : @game.starts_at) < Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time ||
        @game.is_testing? && current_user.author_of?(@game)
      redirect_to game_path(@game), alert: 'Заборонено грати в гру до її початку'
    end
  end

  def ensure_user_has_team
    if @game.team_type == 'multy' && current_user.team_id.nil? || current_user.single_team_id.nil?
      redirect_to game_path(@game), alert: 'Необхідно створити команду або зайти в уже створену'
    end
  end

  def ensure_not_author_of_the_game
    redirect_to game_path(@game), alert: 'Заборонено грати власні ігри' unless @game.is_testing? || !@game.created_by?(current_user)
  end

  def author_finished_at
    redirect_to game_path(@game), alert: 'Гру завершено автором, і ви не можете її більше грати' if @game.author_finished?
  end

  def ensure_captain_exited
    redirect_to game_path(@game), alert: 'Команда зійшла з дистанції' if @game_passing.exited?
  end

  def ensure_team_is_accepted
    redirect_to game_path(@game), alert: 'Команду не прийнято в гру' if (GameEntry.of_game(@game.id).of_team(@game.team_type == 'multy' ? current_user.team.id : current_user.single_team.id).first.nil? || GameEntry.of_game(@game.id).of_team(@game.team_type == 'multy' ? current_user.team.id : current_user.single_team.id).first.status != 'accepted') && !@game.is_testing?
  end

  def ensure_not_finished
    author_finished_at
    ensure_captain_exited
  end

  def get_uniq_level_codes(level)
    Log.of_game(@game.id).of_level(level.id).of_team(@team_id).order(time: :desc).includes(:user).map do |log|
      if log.answer_type == 1
        {
            time: log.time,
            user: log.user.nickname,
            answer: "<span class=\"right_code\">#{log.answer}</span>"
        }
      elsif log.answer_type == 2
        {
                  time: log.time,
                  user: log.user.nickname,
                  answer: "<span class=\"bonus\">#{log.answer}</span>"
               }
      else
        {
                time: log.time,
                user: log.user.nickname,
                answer: log.answer
            }
      end
    end
  end

  def get_answered_questions(level)
    team_questions = level.team_questions(@team_id)
    answered_questions = team_questions.where(id: @game_passing.question_ids)
    team_questions.includes(:answers).map do |question|
      correct_answers = question.answers.select { |ans| ans.team_id.nil? || ans.team_id == @team_id }.map { |answer| answer.value.downcase_utf8_cyr }
      value = level.olymp? ? question.name : '-'
      answered = answered_questions.include?(question)
      {
        id: question.id,
        position: question.position,
        name: question.name,
        answered: answered,
        answer: answered ? @game_passing.get_team_answer(level.id, @team_id, correct_answers) : '',
        value: answered ? "<span class=\"right_code\">#{correct_answers.count == 0 ? nil : @game_passing.get_team_answer(level, Team.find(@team_id), correct_answers)}</span>" : value
      }
    end
  end

  def get_penalty_hints(level)
    level.team_penalty_hints(@team_id).map do |hint|
      is_got_hint = @game_passing.penalty_hints.include?(hint.id)
      current_level_entered_at = (level.position == 1 || @game_passing.game.game_type == 'panic' ? level.game.starts_at : @game_passing.current_level_entered_at)
      current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
      time_to_show = hint.time_to_delay(current_level_entered_at, current_time) || 0
      {
          id: hint.id,
          name: hint.name,
          text: is_got_hint ? hint.text : '',
          used: is_got_hint,
          penalty: hint.penalty,
          delayed: hint.is_delayed,
          time_to_show: is_got_hint || !hint.is_delayed || time_to_show < 0 ? 0 : time_to_show
      }
    end
  end

  def get_answered_bonuses(level)
    return [] unless level.has_bonuses?(@team_id)
    answered_bonuses = level.bonuses.where(id: @game_passing.bonus_ids)
    level.team_bonuses(@team_id).includes(:bonus_answers).map do |bonus|
      correct_answers = bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == @team_id }.map { |answer| answer.value.downcase_utf8_cyr }
      current_level_entered_at = (level.position == 1 || @game_passing.game.game_type == 'panic' ? level.game.starts_at : @game_passing.current_level_entered_at)
      current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
      {
        position: bonus.position,
        id: bonus.id,
        name: bonus.name,
        answered: answered_bonuses.include?(bonus),
        value: answered_bonuses.include?(bonus) ? @game_passing.get_team_bonus_answer(bonus, @team_id, correct_answers) : '',
        task: bonus.task,
        help: answered_bonuses.include?(bonus) ? bonus.help : nil,
        award: answered_bonuses.include?(bonus) ? (bonus.award_time || 0) : nil,
        delayed: bonus.is_delayed_now?(current_level_entered_at, current_time),
        delay_for: bonus.time_to_delay(current_level_entered_at, current_time),
        limited: bonus.is_limited_now?(current_level_entered_at, current_time),
        valid_for: bonus.time_to_miss(current_level_entered_at, current_time),
        missed: @game_passing.missed_bonuses.include?(bonus.id)
      }
    end
  end
end
