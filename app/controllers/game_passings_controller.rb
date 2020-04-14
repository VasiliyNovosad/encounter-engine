class GamePassingsController < ApplicationController
  include GamePassingsHelper

  before_action :authenticate_user!, except: [:index, :show_results]
  before_action :find_game, except: [:exit_game]
  before_action :find_game_by_id, only: [:exit_game]
  before_action :ensure_user_has_team, only: [:show_current_level, :get_current_level_tip, :post_answer, :autocomplete_level, :show_penalty_hint, :get_current_level_bonus, :miss_current_level_bonus]
  before_action :find_team, except: [:show_results, :index]
  before_action :ensure_team_is_accepted, except: [:show_results, :index]
  before_action :ensure_team_size_is_accepted, except: [:show_results, :index]
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
      if !game_finished?(time)
        @level = current_level(params[:level])
        @entered_all_answers = get_uniq_level_codes(@level)
        @bonuses = get_answered_bonuses(@level)
        @sectors = get_answered_questions(@level)
        @penalty_hints = get_penalty_hints(@level)
        @upcoming_hints = @game_passing.upcoming_hints(@team.id, @level)
        @hints_to_show = @game_passing.hints_to_show(@team.id, @level)
        input_lock = get_level_input_lock(time, @level, @level.game_id, @team.id, current_user.id)
        autocomplete_after = 0
        if (@level.complete_later || 0) > 0
          level_number = @game.game_type == 'selected' ? @game_passing.current_level_position(@team.id) : @level.position
          autocomplete_after = ((level_number == 1 ? @game.starts_at : @game_passing.current_level_entered_at) - Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time).to_i + @level.complete_later
          @sectors.each { |sector| autocomplete_after += sector[:change_level_autocomplete_by] }
          @bonuses.each { |bonus| autocomplete_after += bonus[:change_level_autocomplete_by] }
        end
        format.html do
          render layout: 'in_game', locals: {
              game_passing: @game_passing,
              game: @game,
              team_id: @team.id,
              level: @level,
              entered_all_answers: @entered_all_answers,
              bonuses: @bonuses,
              sectors: @sectors,
              penalty_hints: @penalty_hints,
              upcoming_hints: @upcoming_hints,
              hints_to_show: @hints_to_show,
              answer: @answer,
              input_lock: input_lock,
              autocomplete_after: autocomplete_after
          }
        end
        format.json do
          level_position = @game.game_type == 'selected' ? @game_passing.current_level_position(@team.id) : @level.position
          all_sectors = @level.team_questions(@team.id)
          sectors_count = all_sectors.count
          level_time = level_duration
          level_start = @game_passing.level_started_at(@level)
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
                  sectors_closed: @game.game_type == 'panic' ? @game_passing.questions.count : (@game_passing.question_ids.to_set & all_sectors.map(&:id).to_set).size,
                  tasks: @level.team_tasks(@team.id).map { |task| {id: task.id, text: task.text} },
                  messages: @level.messages.map { |message| { user: message.user_nickname, text: message.text} },
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
    upcoming_hints_count = @game_passing.upcoming_hints(@team.id, level).count
    hints_to_show = @game_passing.hints_to_show(@team.id, level)
    hint_to_show_count = hints_to_show.count
    hints_to_show.select! do |hint|
      hint.id == params[:hint].to_i
    end
    last_hint = hints_to_show.last

    render json: {
      hint_num: hint_to_show_count,
      hint_text: (hint_to_show_count.zero? || last_hint.nil? ? '' : last_hint.text.html_safe),
      hint_id: (hint_to_show_count.zero? || last_hint.nil? ? nil : last_hint.id),
      hint_count: hint_to_show_count + upcoming_hints_count
    }
  end

  def get_current_level_bonus
    level_id = params[:level_id]
    level = Level.find(level_id)
    bonus_id = params[:bonus_id]
    bonus = level.bonuses.find(bonus_id)
    current_level_entered_at = level.position == 1 || @game_passing.game_type == 'panic' ? level.game_starts_at : @game_passing.current_level_entered_at
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
    @answer = params[:answer].strip
    return if @answer == ''

    time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    return if game_finished?(time)

    level = current_level(params[:level])
    return if input_lock_exists?(time, level, @game.id, @team.id, current_user.id)

    if need_autocomplete_level?(level)
      time_start = @game_passing.level_started_at(level)
      time_finish = @game_passing.level_finished_at(level)
      if time_finish < time
        Log.add(@game.id, level.id, @team.id, current_user.id, time_finish)
        @game_passing.autocomplete_level!(level, @team.id, time_start, time_finish, current_user.id)
        return
      end
    end

    @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
    @answer_was_correct = @game_passing.check_answer!(@answer, @level, time, current_user)
  end

  def show_results
    game_bonuses = GameBonus.of_game(@game.id).select("team_id, sum(award) as sum_bonuses").group(:team_id).to_a
    game_passings = GamePassing.of_game(@game.id).includes(:team)

    if @game.game_type == 'panic'
      game_finished_at = @game.starts_at + @game.duration * 60
      @game_passings = game_passings.map do |game_passing|
        team_bonus = game_bonuses.select{ |bonus| bonus.team_id == game_passing.team_id}
        {
          team_id: game_passing.team_id,
          team_name: game_passing.team_name,
          finished_at: game_passing.finished_at || game_finished_at,
          closed_levels: game_passing.closed_levels.count,
          sum_bonuses: (game_passing.sum_bonuses || 0) + (team_bonus.empty? ? 0 : (team_bonus[0].sum_bonuses || 0))
        }
      end.sort do |a, b|
        (a[:finished_at] - a[:sum_bonuses]) <=> (b[:finished_at] - b[:sum_bonuses])
      end
    else
      current_time = Time.now
      @game_passings = game_passings.map do |game_passing|
        team_bonus = game_bonuses.select { |bonus| bonus.team_id == game_passing.team_id }
        {
          team_id: game_passing.team_id,
          team_name: game_passing.team_name,
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
      if need_autocomplete_level?(level)
        begin
          time_start = @game_passing.level_started_at(level)
          time_finish = @game_passing.level_finished_at(level)
          if time_finish < time
            Log.add(@game.id, level.id, @team.id, current_user.id, time_finish)
            @game_passing.autocomplete_level!(level, @team.id, time_start, time_finish, current_user.id)
          end
        rescue => e
          p e
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
    current_level_entered_at = @game_passing.level_started_at(level)
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

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_game_by_id
    @game = Game.find(params[:id])
  end

  def find_or_create_game_passing
    @game_passing = GamePassing.of(@team.id, @game.id)
    return unless @game_passing.nil?

    @game_passing = GamePassing.create!(
      team: @team,
      game: @game,
      current_level: @game.game_type == 'selected' ? Level.find_by_id(LevelOrder.of(@game.id, @team.id).order(:position).first.level_id) : @game.levels.first
    )
  end

  def find_team
    @team = @game.team_type == 'multy' ? current_user.team : current_user.single_team
    if @game.is_testing? && !@game.tested_team_id.nil?
      @team = Team.find(@game.tested_team_id)
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
    redirect_to game_path(@game), alert: 'Команду не прийнято в гру' if (GameEntry.of_game(@game.id).of_team(@game.team_type == 'multy' ? current_user.team_id : current_user.single_team_id).first.nil? || GameEntry.of_game(@game.id).of_team(@game.team_type == 'multy' ? current_user.team_id : current_user.single_team_id).first.status != 'accepted') && !@game.is_testing?
  end

  def ensure_team_size_is_accepted
    if @game.team_type == 'multy' && @game.game_size == 'Онлайн' && (@game.team_size_limit || 0) > 0 && current_user.team.members.count > (@game.team_size_limit || 0)
      redirect_to game_path(@game), alert: 'В команді забагато гравців'
    end
  end

  def ensure_not_finished
    author_finished_at
    ensure_captain_exited
  end

  def get_uniq_level_codes(level)
    Log.of_game(@game.id).of_level(level.id).of_team(@team.id).order(time: :desc).includes(:user).map do |log|
      if log.answer_type == 1
        {
          time: log.time,
          user: log.user_nickname,
          answer: "<span class=\"right_code\">#{log.answer}</span>"
        }
      elsif log.answer_type == 2
        {
          time: log.time,
          user: log.user_nickname,
          answer: "<span class=\"bonus\">#{log.answer}</span>"
       }
      else
        {
          time: log.time,
          user: log.user_nickname,
          answer: log.answer
        }
      end
    end
  end

  def get_answered_questions(level)
    team_questions = level.team_questions(@team.id)
    answered_questions = team_questions.where(id: @game_passing.question_ids)
    team_questions.includes(:answers).map do |question|
      correct_answers = question.answers.select { |ans| ans.team_id.nil? || ans.team_id == @team.id }.map { |answer| answer.value.mb_chars.downcase.to_s }
      value = level.olymp? ? question.name : '-'
      answered = answered_questions.include?(question)
      {
        id: question.id,
        position: question.position,
        name: question.name,
        answered: answered,
        answer: answered ? @game_passing.get_team_answer(level.id, @team.id, correct_answers) : '',
        value: answered ? "<span class=\"right_code\">#{correct_answers.size == 0 ? nil : @game_passing.get_team_answer(level, @team.id, correct_answers)}</span>" : value,
        change_level_autocomplete_by: answered && question.change_level_autocomplete? ? question.change_level_autocomplete_by : 0
      }
    end
  end

  def get_penalty_hints(level)
    level.team_penalty_hints(@team.id).order(:created_at).map do |hint|
      is_got_hint = @game_passing.penalty_hints.include?(hint.id)
      current_level_entered_at = @game_passing.level_started_at(level)
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
    return [] unless level.has_bonuses?(@team.id)

    answered_bonuses = level.bonuses.where(id: @game_passing.bonus_ids)
    level.team_bonuses(@team.id).includes(:bonus_answers).map do |bonus|
      correct_answers = bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == @team.id }.map { |answer| answer.value.mb_chars.downcase.to_s }
      current_level_entered_at = @game_passing.level_started_at(level)
      current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
      answered = answered_bonuses.include?(bonus)
      {
        position: bonus.position,
        id: bonus.id,
        name: bonus.name,
        answered: answered,
        value: answered ? @game_passing.get_team_bonus_answer(bonus, @team.id, correct_answers) : '',
        task: bonus.task,
        help: answered ? bonus.help : nil,
        award: answered ? (bonus.award_time || 0) : nil,
        delayed: bonus.is_delayed_now?(current_level_entered_at, current_time),
        delay_for: bonus.time_to_delay(current_level_entered_at, current_time),
        limited: bonus.is_limited_now?(current_level_entered_at, current_time),
        valid_for: bonus.time_to_miss(current_level_entered_at, current_time),
        missed: @game_passing.missed_bonuses.include?(bonus.id),
        change_level_autocomplete_by: answered && bonus.change_level_autocomplete? ? bonus.change_level_autocomplete_by : 0
      }
    end
  end

  private

  def game_finished?(time)
    @game_passing.finished? || @game.game_type == 'panic' && (@game.starts_at + @game.duration * 60 < time)
  end

  def level_duration
    if @game.game_type == 'panic'
      (@level.complete_later || 0).zero? ? @game.duration * 60 : @level.complete_later
    else
      @level.complete_later || 0
    end
  end

  def current_level(level_number)
    if @game.game_type == 'panic'
      level_number ? @game.levels.where(position: level_number).first : @game.levels.first
    else
      @game_passing.current_level
    end
  end

  def input_lock_exists?(time, level, game_id, team_id, user_id)
    return false unless level.input_lock?

    if level.input_lock_type == 'team'
      InputLock.of_game(game_id).of_level(level.id).of_team(team_id).where('lock_ends_at >= ?', time).exists?
    else
      InputLock.of_game(game_id).of_level(level.id).of_team(team_id).of_user(user_id).where('lock_ends_at >= ?', time).exists?
    end
  end

  def get_level_input_lock(time, level, game_id, team_id, user_id)
    return { input_lock: false, duration: 0 } unless level.input_lock?

    input_lock = if level.input_lock_type == 'team'
                   InputLock.of_game(game_id).of_level(level.id).of_team(team_id).where('lock_ends_at >= ?', time).first
                 else
                   InputLock.of_game(game_id).of_level(level.id).of_team(team_id).of_user(user_id).where('lock_ends_at >= ?', time).first
                 end
    return { input_lock: false, duration: 0 } if input_lock.nil?

    { input_lock: true, duration: input_lock.lock_ends_at - time }
  end

  def need_autocomplete_level?(level)
    @game.game_type == 'panic' || level == @game_passing.current_level && !(level.complete_later.nil? || level.complete_later.zero?)
  end

  def level_start_finish(level)
    time_start = @game_passing.level_started_at(level)
    bonuses = get_answered_bonuses(level)
    sectors = get_answered_questions(level)
    change_by_sectors = 0
    sectors.each { |sector| change_by_sectors += sector[:change_level_autocomplete_by] }
    change_by_bonuses = 0
    bonuses.each { |bonus| change_by_bonuses += bonus[:change_level_autocomplete_by] }

    time_finish = time_start + level.complete_later + change_by_sectors + change_by_bonuses

    [time_start, time_finish]
  end
end
