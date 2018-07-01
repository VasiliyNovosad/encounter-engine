require 'ee_strings.rb'

class GamePassingsController < ApplicationController
  include GamePassingsHelper

  before_action :authenticate_user!, except: [:index, :show_results]
  before_action :find_game, except: [:exit_game]
  before_action :find_game_by_id, only: [:exit_game]
  before_action :ensure_user_has_team, only: [:show_current_level, :get_current_level_tip, :post_answer, :autocomplete_level, :penalty_hint]
  before_action :find_team, except: [:show_results, :index]
  before_action :find_team_id, only: [:show_current_level, :get_current_level_tip, :post_answer, :autocomplete_level, :penalty_hint]
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
    if @game_passing.finished_at.nil? && !(@game.game_type == 'panic' && (@game.starts_at + @game.duration * 60) < Time.now)
      @level = if @game.game_type == 'panic'
                 params[:level] ? @game.levels.where(position: params[:level]).first : @game.levels.first
               else
                 @game_passing.current_level
               end
      get_uniq_level_codes(@level)
      get_answered_bonuses(@level) # unless @game.game_type == 'panic'
      get_answered_questions(@level) # unless @game.game_type == 'panic'
      get_penalty_hints(@level)
      render layout: 'in_game'
    else
      redirect_to  game_passings_show_results_url(game_id: @game.id)
    end
  end

  def index
    @game_passings = GamePassing.of_game(@game)
    render
  end

  def get_current_level_tip
    level_id = params[:level_id]
    level = Level.find(level_id)
    upcoming_hints = @game_passing.upcoming_hints(@team_id, level).to_a
    next_hint = upcoming_hints.count > 0 ? upcoming_hints.first : nil
    hints_to_show = @game_passing.hints_to_show(@team_id, level)

    render json: { hint_num: hints_to_show.count,
                   hint_text: (hints_to_show.count == 0 ? '' : hints_to_show.last.text.html_safe),
                   hint_count: hints_to_show.count + upcoming_hints.count,
                   next_available_in: next_hint.nil? ? nil : next_hint.available_in(@game_passing.game.game_type == 'panic' || level.position == 1 ? @game_passing.game.starts_at : @game_passing.current_level_entered_at) }.to_json
  end

  def get_current_level_bonus

    render json: {}
  end

  def miss_current_level_bonus
    level_id = params[:level_id]
    bonus_id = params[:bonus_id]
    @game_passing.miss_bonus!(level_id, bonus_id)

    render json: {}
  end

  def post_answer
    time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    if @game_passing.finished? ||
       @game.game_type == 'panic' &&
       @game.starts_at + 60 * @game.duration < time
      respond_to do |format|
        format.html { redirect_to game_passings_show_results_url(game_id: @game.id) }
        format.js
      end
    else
      @answer = params[:answer].strip
      if @answer == ''
        respond_to do |format|
          format.html do
            @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
            get_uniq_level_codes(@level)
            get_answered_bonuses(@level) #unless @game.game_type == 'panic'
            get_answered_questions(@level) #unless @game.game_type == 'panic'
            get_penalty_hints(@level)
            render 'show_current_level', layout: 'in_game'
          end
          format.js
        end
      else
        @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
        save_log(@level, time) if @game_passing.current_level.id || @game.game_type == 'panic'
        answer_was_correct = @game_passing.check_answer!(@answer, @level, @team_id, time, current_user)
        @answer_was_correct = answer_was_correct[:correct] || answer_was_correct[:bonus]
        answered = []
        if @answer_was_correct
          if answer_was_correct[:correct]
            answered.push(
              {
                  time: time.strftime("%H:%M:%S"),
                  user: current_user.nickname,
                  answer: "<span class=\"right_code\">#{@answer}</span>"
              })
          end
          if answer_was_correct[:bonus]
            answered.push(
                {
                    time: time.strftime("%H:%M:%S"),
                    user: current_user.nickname,
                    answer: "<span class=\"bonus\">#{@answer}</span>"
                }
            )
          end
        else
          answered.push(
              {
                  time: time.strftime("%H:%M:%S"),
                  user: current_user.nickname,
                  answer: @answer
              }
          )
        end
        PrivatePub.publish_to "/game_passings/#{@game_passing.id}/#{@level.id}/answers", {
            answers: answered,
            sectors: answer_was_correct[:sectors],
            bonuses: answer_was_correct[:bonuses],
            needed: answer_was_correct[:needed],
            closed: answer_was_correct[:closed]
        }
        if @game_passing.finished?
          PrivatePub.publish_to "/game_passings/#{@game_passing.id}/#{@level.id}", url: '/game_passings/show_results'
          respond_to do |format|
            format.html { redirect_to game_passings_show_results_url(game_id: @game.id) }
            format.js
          end
        else
          respond_to do |format|
            format.html do
              @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
              get_uniq_level_codes(@level)
              get_answered_bonuses(@level) # unless @game.game_type == 'panic'
              get_answered_questions(@level) # unless @game.game_type == 'panic'
              get_penalty_hints(@level)
              render 'show_current_level', layout: 'in_game'
            end
            format.js
          end
        end
      end
    end
  end

  def save_log(level = @game_passing.current_level, time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    Log.create! game_id: @game.id,
                level: level.name,
                level_id: level.id,
                team: @team.name,
                team_id: @team.id,
                time: time,
                answer: @answer || 'timeout',
                user: current_user
  end

  def show_results
    @game_bonuses = GameBonus.of_game(@game).select("team_id, sum(award) as sum_bonuses").group(:team_id).to_a
    @game_passings = GamePassing.of_game(@game)

    unless @game.game_type == 'linear' || @game.game_type == 'selected'
      @game_finished_at = @game.starts_at + @game.duration * 60
      @game_passings = @game_passings.map do |game_passing|
        team_bonus = @game_bonuses.select{ |bonus| bonus.team_id == game_passing.team_id}
        {
            team_id: game_passing.team.id,
            team_name: game_passing.team.name,
            finished_at: game_passing.finished_at || @game_finished_at,
            closed_levels: game_passing.closed_levels.count,
            sum_bonuses: (game_passing.sum_bonuses || 0) + (team_bonus.empty? ? 0 : team_bonus[0].sum_bonuses)
        }
      end.sort do |a, b|
        (a[:finished_at] - a[:sum_bonuses]) <=> (b[:finished_at] - b[:sum_bonuses])
      end
    end
  end

  def exit_game
    @game_passing.exit!
    redirect_to game_passings_show_results_url(game_id: @game.id)
  end

  def autocomplete_level
    level_id = params[:level]
    unless @game_passing.finished?
      level = Level.find(level_id)
      @game_passing = GamePassing.of(@team, @game)
      if level == @game_passing.current_level
        begin
          time_finish = (level.position == 1 ? @game.starts_at : @game_passing.current_level_entered_at) + level.complete_later
          save_log(level, time_finish)
          @game_passing.autocomplete_level!(level, @team_id, time_finish)
        rescue

        end
      end
    end
    render json: { result: true }.to_json
  end

  def penalty_hint
    level_id = params[:level_id]
    penalty_hint_id = params[:hint_id]
    @game_passing.use_penalty_hint!(level_id, penalty_hint_id, current_user.id)
    respond_to do |format|
      format.js
    end
  end

  protected

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_game_by_id
    @game = Game.find(params[:id])
  end

  def find_or_create_game_passing
    @game_passing = GamePassing.of(@team, @game)

    if @game_passing.nil?
      @game_passing = GamePassing.create! team: @team,
                                          game: @game,
                                          current_level: @game.game_type == 'selected' ? Level.find_by_id(LevelOrder.of(@game, Team.find_by_id(@team_id)).first.level_id) : @game.levels.first
    end
  end

  def find_team
    @team = current_user.team
    if @game.is_testing? && !@game.tested_team_id.nil?
      @team = Team.find(@game.tested_team_id)
    end
  end

  def find_team_id
    @team_id = current_user.team.id
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
    if current_user.team.nil?
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
    redirect_to game_path(@game), alert: 'Команду не прийнято в гру' if (GameEntry.of_game(@game).of_team(current_user.team).first.nil? || GameEntry.of_game(@game).of_team(current_user.team).first.status != 'accepted') && !@game.is_testing?
  end

  def ensure_not_finished
    author_finished_at
    ensure_captain_exited
  end

  def get_uniq_level_codes(level)
    correct_answers = []
    level.team_questions(@team_id).includes(:answers).each do |question|
      question.answers.select{ |answer| answer.team_id.nil? || answer.team_id == @team_id }.each do |answer|
        correct_answers << answer.value
      end
    end
    correct_bonus_answers = []
    level.team_bonuses(@team_id).includes(:bonus_answers).each do |bonus|
      bonus.bonus_answers.select{ |answer| answer.team_id.nil? || answer.team_id == @team_id }.each do |answer|
        correct_bonus_answers << answer.value
      end
    end

    log_of_level = []
    Log.of_game(@game).of_level(level).of_team(Team.find(@team_id)).order(time: :desc).includes(:user).each do |log|
      if correct_answers.include?(log.answer)
        log_of_level.push(
            {
            time: log.time,
            user: log.user.nickname,
            answer: "<span class=\"right_code\">#{log.answer}</span>"
        })
      end
      if correct_bonus_answers.include?(log.answer)
        log_of_level.push(
          {
                  time: log.time,
                  user: log.user.nickname,
                  answer: "<span class=\"bonus\">#{log.answer}</span>"
               }
        )
      end
      unless correct_answers.include?(log.answer) || correct_bonus_answers.include?(log.answer)
        log_of_level.push(
            {
                time: log.time,
                user: log.user.nickname,
                answer: log.answer
            }
        )
      end
    end
    # entered_answers = log_of_level.map(&:answer).uniq || []
    @entered_all_answers = log_of_level # entered_answers

    # @entered_correct_answers = entered_answers & correct_answers
  end

  def get_answered_questions(level)
    @sectors = []
    return unless level.multi_question?(@team_id)
    answered_questions = level.questions.where(id: @game_passing.answered_questions)
    level.team_questions(@team_id).includes(:answers).each do |question|
      correct_answers = question.answers.select { |ans| ans.team_id.nil? || ans.team_id == @team_id }.map { |answer| answer.value.downcase_utf8_cyr }
      value = level.olymp? ? question.name : '-'
      @sectors << { position: question.position,
                    name: question.name,
                    value: answered_questions.include?(question) ? "<span class=\"right_code\">#{correct_answers.count == 0 ? nil : @game_passing.get_team_answer(level, Team.find(@team_id), correct_answers)}</span>" : value }
    end
  end

  def get_penalty_hints(level)
    @penalty_hints = []
    level.team_penalty_hints(@team_id).each do |hint|
      is_get_hint = @game_passing.penalty_hints.include?(hint.id)
      @penalty_hints << { id: hint.id, name: hint.name, text: is_get_hint ? hint.text : '', used: is_get_hint, penalty: hint.penalty}
    end
    @penalty_hints
  end

  def get_answered_bonuses(level)
    @bonuses = []
    return unless level.has_bonuses?(@team_id)
    answered_bonuses = level.bonuses.where(id: @game_passing.answered_bonuses)
    @bonuses = level.team_bonuses(@team_id).includes(:bonus_answers).map do |bonus|
      correct_answers = bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == @team_id }.map { |answer| answer.value.downcase_utf8_cyr }
      {
        position: bonus.position,
        id: bonus.id,
        name: bonus.name,
        answered: answered_bonuses.include?(bonus),
        value: answered_bonuses.include?(bonus) ? @game_passing.get_team_answer(level, Team.find(@team_id), correct_answers) : '',
        task: bonus.task,
        help: answered_bonuses.include?(bonus) ? bonus.help : nil,
        award: answered_bonuses.include?(bonus) ? (bonus.award_time || 0) : nil,
        delayed: false,
        delay_for: 0,
        limited: false,
        valid_for: 0,
        missing: false
      }
    end
    @bonuses
  end
end
