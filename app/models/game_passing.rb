class GamePassing < ActiveRecord::Base

  serialize :answered_questions, coder: YAML
  default_value_for :answered_questions, []
  serialize :answered_bonuses, coder: YAML
  default_value_for :answered_bonuses, []
  serialize :closed_levels, coder: YAML
  default_value_for :closed_levels, []
  serialize :penalty_hints, coder: YAML
  default_value_for :penalty_hints, []
  serialize :missed_bonuses, coder: YAML
  default_value_for :missed_bonuses, []

  belongs_to :team
  belongs_to :game
  belongs_to :current_level, class_name: 'Level'
  has_and_belongs_to_many :questions, join_table: 'game_passings_questions'
  has_and_belongs_to_many :bonuses, join_table: 'game_passings_bonuses'

  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }
  scope :ended_by_author, -> { where(status: 'ended').order('current_level_id DESC') }
  scope :exited, -> { where(status: 'exited').order('finished_at DESC') }
  scope :finished, -> { where('finished_at IS NOT NULL') }
  scope :finished_before, ->(time) { where('finished_at < ?', time) }

  delegate :name, to: :team, prefix: true
  delegate :game_type, to: :game, prefix: false

  before_create :update_current_level_entered_at

  def self.of(team_id, game_id)
    game_passings = of_team(team_id).of_game(game_id)
    if game_passings.count == 1
      game_passings.first
    elsif game_passings.count > 1
      game_passings.last.delete
      game_passings.first
    end
  end

  def check_answer!(answer, level, time, user)
    time_str = time.strftime("%H:%M:%S")
    answered_bonus, is_correct_bonus_answer = pass_bonuses!(answer, level, team_id, user)
    answered_question, is_correct_answer, needed, closed = pass_questions!(answer, level, team_id, user)
    start_time = level_started_at(level)
    if level[:is_wrong_code_penalty] && !level[:wrong_code_penalty].zero? && !is_correct_bonus_answer && !is_correct_answer
      GameBonus.create!(
        game_id: game_id,
        level_id: level.id,
        team_id: team_id,
        award: -level[:wrong_code_penalty],
        user_id: user.id,
        reason: 'штраф за неіснуючий код ' + answer,
        description: ''
      )
    end
    answer_was_correct = {
      correct: is_correct_answer,
      bonus: is_correct_bonus_answer,
      sectors: answered_question,
      bonuses: answered_bonus,
      needed: needed,
      closed: closed
    }

    answered = []
    input_lock = nil
    if answer_was_correct[:correct] || answer_was_correct[:bonus]
      if answer_was_correct[:correct]
        Log.add(game_id, level.id, team_id, user.id, time, answer, 1)
        answered.push(
          time: time_str,
          user: user.nickname,
          answer: "<span class=\"right_code\">#{answer}</span>"
        )
      end
      if answer_was_correct[:bonus]
        Log.add(game_id, level.id, team_id, user.id, time, answer, 2)
        answered.push(
          time: time_str,
          user: user.nickname,
          answer: "<span class=\"bonus\">#{answer}</span>"
        )
      end
    else
      Log.add(game_id, level.id, team_id, user.id, time, answer, 0)
      answered.push(
        time: time_str,
        user: user.nickname,
        answer: answer
      )
      input_lock = set_input_lock(time, level, game_id, team_id, user.id) if level.input_lock
    end

    if level.questions.count.positive? && (all_questions_answered?(level, team_id) || ((level.sectors_for_close || 0) > 0 && closed >= level.sectors_for_close))
      pass_level!(level, team_id, time, start_time, user.id)
      return answer_was_correct[:correct] || answer_was_correct[:bonus]
    end

    finish_time = level.complete_later&.positive? ? level_finished_at(level) : nil
    Concurrent::Future.execute do
      ActionCable.server.broadcast(
        "game_passings_#{id}_#{level.id}_0",
        {
          answers: answered,
          sectors: answer_was_correct[:sectors],
          bonuses: answer_was_correct[:bonuses],
          needed: answer_was_correct[:needed],
          closed: answer_was_correct[:closed],
          input_lock: input_lock.nil? || level.input_lock_type == 'member' ? { input_lock: false, duration: 0 } : { input_lock: true, duration: input_lock.lock_ends_at - time },
          timer_left: level.complete_later&.positive? ? (finish_time - time).to_i : nil,
          game: { id: game.id, type: game.game_type },
          level: {
            id: level.id,
            olymp: level.olymp?,
            position: game.game_type == 'selected' ? current_level_position(team_id) : level.position
          }
        }
      )
    end
    unless input_lock.nil? || level.input_lock_type == 'team'
      Concurrent::Future.execute do
        ActionCable.server.broadcast(
          "game_passings_#{id}_#{level.id}_#{user.id}",
          {
            input_lock: { input_lock: true, duration: input_lock.lock_ends_at - time }
          }
        )
      end
    end
    if game.game_type == 'panic' && !answer_was_correct[:bonuses].nil?
      send_bonuses_to_panic(answer_was_correct[:bonuses])
    end
    answer_was_correct[:correct] || answer_was_correct[:bonus]
  end

  def pass_question!(questions)
    return false if questions.empty?

    self.question_ids = question_ids + questions.map { |q| q[:id] }
    true
  end

  def pass_bonus!(bonuses)
    return false if bonuses.empty?

    changed = false
    bonuses.each do |bonus|
      next if bonus_ids.include?(bonus[:id])

      self.bonus_ids = bonus_ids + [bonus[:id]]
      game_bonus_options = {
        game_id: game_id,
        level_id: bonus[:level_id],
        team_id: team_id,
        award: bonus[:bonus],
        user_id: bonus[:user_id],
        reason: "за бонус: #{bonus[:name]}",
        description: ''
      }
      unless bonus[:bonus].zero? || GameBonus.exists?(game_bonus_options)
        GameBonus.create(game_bonus_options)
      end
      changed = true
    end
    changed
  end

  def pass_level!(level, team_id, time, time_start, user_id)
    lock!
    return save! if closed?(level)

    set_level_finish_time(level, team_id, time)
    ClosedLevel.close_level!(game_id, level.id, team_id, user_id, time_start, time)
    save!
    Concurrent::Future.execute do
      ActionCable.server.broadcast(
        "game_passings_#{id}_#{level.id}_0",
        {
          url: finished? ? "/game_passings/show_results?game_id=#{game_id}" : game_url(level)
        }
      )
    end
  end

  def closed?(level)
    closed_levels.include? level.id
  end

  def finished?
    !!finished_at
  end

  def hints_to_show(team_id, level = current_level)
    level_start_time = level.position == 1 || game.game_type == 'panic' ? game.starts_at : current_level_entered_at
    level.hints.of_team(team_id).select { |hint| hint.ready_to_show?(level_start_time) }
  end

  def upcoming_hints(team_id, level = current_level)
    level_start_time = level.position == 1 || game.game_type == 'panic' ? game.starts_at : current_level_entered_at
    level.hints.of_team(team_id).reject { |hint| hint.ready_to_show?(level_start_time) }
  end

  def correct_answer?(answer, level, team_id)
    level.team_questions(team_id).includes(:answers).any? do |question|
      question.team_answers(team_id).any? do |ans|
        ans.value.mb_chars.downcase.to_s == answer.mb_chars.downcase.to_s
      end
    end
  end

  def correct_bonus_answer?(answer, level, team_id)
    level.team_bonuses(team_id).includes(:bonus_answers).any? do |bonus|
      (!missed_bonuses.include?(bonus.id) || bonus_ids.include?(bonus.id)) && !bonus.is_delayed_now?(level.position == 1 || game_type == 'panic' ? game.starts_at : current_level_entered_at) &&
        bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == team_id }.any? do |ans|
          ans.value.mb_chars.downcase.to_s == answer.mb_chars.downcase.to_s
        end
    end
  end

  def time_at_level
    difference = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time - current_level_entered_at
    hours, minutes, seconds = seconds_fraction_to_time(difference)
    '%02d:%02d:%02d' % [hours, minutes, seconds]
  end

  def unanswered_questions(level, team_id)
    level.team_questions(team_id) - Question.where(id: question_ids)
  end

  def all_questions_answered?(level, team_id)
    (level.team_questions(team_id) - Question.where(id: question_ids)).empty?
  end

  def unanswered_bonuses(level, team_id)
    level.team_bonuses(team_id) - Bonus.where(id: bonus_ids)
  end

  def exit!
    self.finished_at = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    self.status = 'exited'
    save!
  end

  def exited?
    status == 'exited'
  end

  def end!
    return if exited?

    self.status = 'ended'
    save!
  end

  def autocomplete_level!(level, team_id, time_start, time_finish, user_id)
    lock!
    return save! if closed?(level)

    set_level_finish_time(level, team_id, time_finish)
    add_autocomplete_penalty(level, team_id, user_id)
    ClosedLevel.close_level!(game_id, level.id, team_id, user_id, time_start, time_finish, true)
    save!
  end

  def use_penalty_hint!(level_id, penalty_hint_id, user_id)
    level = Level.find(level_id)
    penalty_hint = level.penalty_hints.find(penalty_hint_id)
    return if penalty_hint.nil? || penalty_hints.include?(penalty_hint.id)

    penalty_hints << penalty_hint.id
    save!

    unless penalty_hint.penalty.zero?
      GameBonus.create(
        game_id: game_id,
        level_id: level_id,
        team_id: team_id,
        award: - penalty_hint.penalty,
        user_id: user_id,
        reason: 'за штрафну підказку',
        description: ''
      )
    end
    Concurrent::Future.execute do
      ActionCable.server.broadcast(
        "game_passings_#{id}_#{level.id}_0",
        {
          hint: {
            id: penalty_hint.id,
            name: penalty_hint.name,
            text: penalty_hint.text,
            used: true,
            penalty: penalty_hint.penalty
          }
        }
      )
    end
  end

  def miss_bonus!(level_id, bonus_id)
    lock!
    level = Level.find(level_id)
    bonus = level.bonuses.find(bonus_id)
    unless missed_bonuses.include?(bonus_id) || bonus.nil?
      missed_bonuses << bonus_id
    end
    save!
  end

  def current_level_position(team_id)
    LevelOrder.of(game_id, team_id).where(level_id: current_level.id).first.position
  end

  def get_team_answer(level_id, team_id, correct_answers)
    log = Log.of_game(game_id).of_level(level_id).of_team(team_id).where('lower(answer) IN (?)', correct_answers).first
    log.nil? ? '' : "#{log.answer} (#{log.user_nickname})"
  end

  def get_team_bonus_answer(bonus, team_id, correct_answers)
    log = Log.of_game(game_id).of_team(team_id).where(level_id: bonus.levels.pluck(:id)).where('lower(answer) IN (?)', correct_answers).first
    log.nil? ? '' : "#{log.answer} (#{log.user_nickname})"
  end

  def level_started_at(level)
    if level.position == 1 || game.game_type == 'panic'
      level.game_starts_at
    else
      current_level_entered_at
    end
  end

  def level_finished_at(level)
    level_started_at(level) + (level.complete_later || 1_000_000_000_000) + get_answered_questions(level) + get_answered_bonuses(level)
  end

  protected

  def last_level_selected?(team_id)
    level_position = LevelOrder.of(game_id, team_id).where(level_id: current_level.id).first.position
    LevelOrder.of(game_id, team_id).where(position: level_position + 1).first.nil?
  end

  def next_selected_level(level, team_id)
    level_position = LevelOrder.of(game_id, team_id).where(level_id: level.id).first.position
    Level.find_by_id(LevelOrder.of(game_id, team_id).where(position: level_position + 1).first.level_id)
  end

  def update_current_level_entered_at(time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    self.current_level_entered_at = time
  end

  def set_finish_time(time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    self.finished_at = time
  end

  def get_finish_time(time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    if game.game_type == 'panic'
      closed_levels_times = ClosedLevel.of_game(game_id).of_team(team_id).pluck(:closed_at)
      closed_levels_times.push(time)
      closed_levels_times.max
    else
      time
    end
  end

  def reset_answered_questions
    answered_questions.clear
  end

  def reset_answered_bonuses
    answered_bonuses.clear
  end

  def reset_questions
    questions.clear
  end

  def reset_bonuses
    bonuses.clear
  end

  # TODO: keep SRP, extract this to a separate helper
  def seconds_fraction_to_time(seconds)
    hours = minutes = 0
    if seconds >= 60
      minutes = (seconds / 60).to_i
      seconds = (seconds % 60).to_i

      if minutes >= 60
        hours = (minutes / 60).to_i
        minutes = (minutes % 60).to_i
      end
    end
    [hours, minutes, seconds]
  end

  def seconds_to_string(seconds)
    sign = seconds < 0 ? '-' : ''

    minutes = (seconds.abs / 60).floor
    seconds = seconds.abs % 60
    hours = (minutes / 60).floor
    minutes = minutes % 60
    days = (hours / 24).floor
    hours = hours % 24

    output = sign
    output << "#{days} дн " if days > 0
    output << "#{hours} г " if hours > 0
    output << "#{minutes} хв " if minutes > 0
    output << "#{seconds} с" if seconds > 0

    output
  end

  private

  def set_level_finish_time(level, team_id, time_finish)
    closed_levels << level.id unless closed?(level)
    if last_level?(level, team_id)
      set_finish_time(time_finish)
    else
      update_current_level_entered_at(time_finish)
      if game.game_type == 'linear'
        self.current_level = level.next
      elsif game.game_type == 'selected'
        self.current_level = next_selected_level(level, team_id)
      end
    end
  end

  def game_url(level)
    game.game_type == 'panic' ? "/play/#{game_id}?level=#{level.position}&rnd=#{rand}" : "/play/#{game_id}?rnd=#{rand}"
  end

  def add_autocomplete_penalty(level, team_id, user_id)
    game_bonus_options = {
      game_id: game_id,
      level_id: level.id,
      team_id: team_id,
      award: -(level.autocomplete_penalty || 0),
      user_id: user_id,
      reason: 'штраф за автоперехід',
      description: ''
    }
    if level.is_autocomplete_penalty? && !level.autocomplete_penalty.zero? && !GameBonus.exists?(game_bonus_options)
      GameBonus.create(game_bonus_options)
    end
  end

  def last_level?(level, team_id)
    game.game_type == 'linear' && current_level.next.nil? ||
      game.game_type == 'panic' &&
        closed_levels.count == game.levels.count ||
      game.game_type == 'selected' && last_level_selected?(team_id)
  end

  def pass_bonuses!(answer, level, team_id, user)
    return [[], false] unless correct_bonus_answer?(answer, level, team_id)

    answered_bonus = []
    level.find_bonuses_by_answer(answer, team_id).each do |q|
      next if bonus_ids.include?(q.id)

      answered_bonus << {
        id: q.id,
        position: q.position,
        bonus: q.award_time || 0,
        award: seconds_to_string(q.award_time || 0),
        help: q.help,
        name: q.name,
        value: "#{answer} (#{user.nickname})",
        level_id: level.id,
        user_id: user.id
      }
    end
    pass_bonus!(answered_bonus) unless answered_bonus.size.zero?
    [answered_bonus, true]
  end

  def pass_questions!(answer, level, team_id, user)
    return [[], false, 0, 0] unless correct_answer?(answer, level, team_id)

    answered_question = []
    level.find_questions_by_answer(answer, team_id).each do |q|
      next if question_ids.include?(q.id)

      answered_question << {
        id: q.id,
        name: q.name,
        position: q.position,
        value: "<span class=\"right_code\">#{answer} (#{user.nickname})</span>"
      }
    end
    pass_question!(answered_question)
    needed = level.team_questions(team_id).count
    closed = (question_ids.to_set & level.team_questions(team_id).map(&:id).to_set).size
    [answered_question, true, needed, closed]
  end

  def set_input_lock(time, level, game_id, team_id, user_id)
    input_lock_type = level.input_lock_type
    input_lock_duration = level.input_lock_duration
    inputs_count = level.inputs_count
    input_lock = nil
    if count_wrong_answers(time - input_lock_duration, level.id, game_id, team_id, user_id, input_lock_type) >= inputs_count
      input_lock = InputLock.create!(
        game_id: game_id,
        level_id: level.id,
        team_id: team_id,
        user_id: user_id,
        lock_ends_at: time + input_lock_duration
      )
    end
    input_lock
  end

  def count_wrong_answers(time, level_id, game_id, team_id, user_id, input_lock_type)
    if input_lock_type == 'team'
      Log.of_game(game_id).of_level(level_id).of_team(team_id).where(answer_type: 0).where('time >= ?', time).count
    else
      Log.of_game(game_id).of_level(level_id).of_team(team_id).where(user_id: user_id, answer_type: 0).where('time >= ?', time).count
    end
  end

  def send_bonuses_to_panic(bonuses)
    levels = Hash.new { |h, k| h[k] = { olymp: false, bonuses: [] } }
    bonuses.each do |bonus|
      Bonus.joins(:levels).where(id: bonus[:id]).pluck('levels.id, levels.olymp').each do |level_id, level_olymp|
        levels[level_id][:olymp] = level_olymp
        levels[level_id][:bonuses].push(bonus.merge(level_id: level_id)) unless level_id == bonus[:level_id]
      end
    end
    levels.each do |k, v|
      Concurrent::Future.execute do
        ActionCable.server.broadcast(
          "game_passings_#{id}_#{k}_0",
          {
            answers: [],
            sectors: [],
            bonuses: v[:bonuses],
            needed: [],
            closed: [],
            input_lock: { input_lock: false, duration: 0 },
            game: { id: game.id, type: game.game_type },
            level: {
              id: k,
              olymp: v[:olymp],
              position: game.game_type == 'selected' ? current_level_position(team_id) : level.position
            }
          }
        )
      end
    end
  end

  def get_answered_bonuses(level)
    sum = 0
    level.bonuses.where(id: bonus_ids).each do |bonus|
      sum += bonus.change_level_autocomplete? ? bonus.change_level_autocomplete_by : 0
    end
    sum
  end

  def get_answered_questions(level)
    sum = 0
    level.questions.where(id: question_ids).each do |question|
      sum += question.change_level_autocomplete? ? question.change_level_autocomplete_by : 0
    end
    sum
  end
end
