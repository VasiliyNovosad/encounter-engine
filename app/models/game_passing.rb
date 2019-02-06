class GamePassing < ActiveRecord::Base
  require 'ee_strings.rb'

  serialize :answered_questions
  default_value_for :answered_questions, []
  serialize :answered_bonuses
  default_value_for :answered_bonuses, []
  serialize :closed_levels
  default_value_for :closed_levels, []
  serialize :penalty_hints
  default_value_for :penalty_hints, []
  serialize :missed_bonuses
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
  scope :finished, -> { where('finished_at IS NOT NULL') } # .order("(finished_at - sum_bonuses * interval '1 second') ASC") }
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

  def check_answer!(answer, level, team_id, time, user)
    answer.strip!
    is_correct_answer = false
    is_correct_bonus_answer = false
    needed = 0
    closed = 0
    answered_bonus = []
    if correct_bonus_answer?(answer, level, team_id)
      answered_bonus = level.find_bonuses_by_answer(answer, team_id).map do |q|
        {
          id: q.id,
          position: q.position,
          bonus: q.award_time || 0,
          award: seconds_to_string(q.award_time || 0),
          help: q.help,
          name: q.name,
          value: "#{answer} (#{user.nickname})",
          level_id: level.id,
          user_id: user.id
        } unless bonus_ids.include?(q.id)
      end.compact
      pass_bonus!(answered_bonus)
      is_correct_bonus_answer = true
    end
    answered_question = []
    if correct_answer?(answer, level, team_id)
      answered_question = level.find_questions_by_answer(answer, team_id).map do |q|
        {
          id: q.id,
          name: q.name,
          position: q.position,
          value: "<span class=\"right_code\">#{answer} (#{user.nickname})</span>"
        } unless question_ids.include?(q.id)
      end.compact
      changed = pass_question!(answered_question)
      is_correct_answer = true
      needed = level.team_questions(team_id).count
      closed = (question_ids.to_set & level.team_questions(team_id).map(&:id).to_set).count
      start_time = level.position == 1 || game.game_type == 'panic' ? game.starts_at : current_level_entered_at
      pass_level!(level, team_id, time, start_time, user.id) if all_questions_answered?(level, team_id) || ((level.sectors_for_close || 0) > 0 && closed >= level.sectors_for_close)
    end
    if level[:is_wrong_code_penalty] && !is_correct_bonus_answer && !is_correct_answer && !level[:wrong_code_penalty].zero?
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
    {
      correct: is_correct_answer,
      bonus: is_correct_bonus_answer,
      sectors: answered_question,
      bonuses: answered_bonus,
      needed: needed,
      closed: closed
    }
  end

  def pass_question!(questions)
    changed = false
    unless questions.empty?
      changed = true
      self.question_ids = question_ids + questions.map { |q| q[:id] }
      # self.answered_questions += questions.map { |q| q[:id] }
    end
    changed
  end

  def pass_bonus!(bonuses)
    changed = false
    unless bonuses.empty?
      bonuses.each do |bonus|
        unless bonus_ids.include?(bonus[:id])
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
          unless bonus[:bonus].zero? || GameBonus.where(game_bonus_options).count > 0
            GameBonus.create!(game_bonus_options)
          end
          changed = true
        end
      end
    end
    changed
  end

  def pass_level!(level, team_id, time, time_start, user_id)
    lock!
    unless closed?(level)
      if game.game_type == 'linear' && last_level? ||
        game.game_type == 'panic' && !closed?(level) &&
        closed_levels.count == game.levels.count - 1 ||
        game.game_type == 'selected' && last_level_selected?(team_id)
        closed_levels << level.id unless closed?(level)
        set_finish_time(time)
      else
        update_current_level_entered_at(time)
        closed_levels << level.id unless closed?(level)
        # reset_answered_questions unless game.game_type == 'panic'
        # reset_answered_bonuses unless game.game_type == 'panic'
        if game.game_type == 'linear'
          self.current_level = level.next
        elsif game.game_type == 'selected'
          self.current_level = next_selected_level(level, team_id)
        end
      end
      ClosedLevel.close_level!(game_id, level.id, team_id, user_id, time_start, time)
      PrivatePub.publish_to "/game_passings/#{id}/#{level.id}", url: game.game_type == 'panic'? "/play/#{game_id}?level=#{level.position}" : "/play/#{game_id}"
    end
    save!
  end

  def closed?(level)
    closed_levels.include? level.id
  end

  def finished?
    !!finished_at
  end

  def hints_to_show(team_id, level = current_level)
    if level.position == 1 || game.game_type == 'panic'
      level.hints.of_team(team_id).select { |hint| hint.ready_to_show?(game.starts_at) }
    else
      level.hints.of_team(team_id).select { |hint| hint.ready_to_show?(current_level_entered_at) }
    end
  end

  def upcoming_hints(team_id, level = current_level)
    if level.position == 1 || game.game_type == 'panic'
      level.hints.of_team(team_id).select { |hint| !hint.ready_to_show?(game.starts_at) }
    else
      level.hints.of_team(team_id).select { |hint| !hint.ready_to_show?(current_level_entered_at) }
    end
  end

  def correct_answer?(answer, level, team_id)
    # unanswered_questions(level, team_id).any? { |question| question.matches_any_answer(answer, team_id) }
    # level.team_questions(team_id).any? { |question| question.matches_any_answer(answer, team_id) }
    level.team_questions(team_id).includes(:answers).any? do |question|
      # bonus.matches_any_answer(answer, team_id)
      question.answers.select { |ans| ans.team_id.nil? || ans.team_id == team_id }.any? do |ans|
        ans.value.to_s.downcase_utf8_cyr == answer.to_s.downcase_utf8_cyr
      end
    end
  end

  def correct_bonus_answer?(answer, level, team_id)
    # unanswered_bonuses(level, team_id).any? { |bonus| bonus.matches_any_answer(answer, team_id) }
    level.team_bonuses(team_id).includes(:bonus_answers).any? do |bonus|
      # bonus.matches_any_answer(answer, team_id)
      (!missed_bonuses.include?(bonus.id) || bonus_ids.include?(bonus.id) ) && !bonus.is_delayed_now?(level.position == 1 || game_type == 'panic' ? game.starts_at : current_level_entered_at) &&
        bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == team_id }.any? do |ans|
          ans.value.to_s.downcase_utf8_cyr == answer.to_s.downcase_utf8_cyr
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
    self.save!
  end

  def exited?
    status == 'exited'
  end

  def end!
    unless self.exited?
      self.status = 'ended'
      self.save!
    end
  end

  def autocomplete_level!(level, team_id, time_start, time_finish, user_id)
    lock!
    unless closed?(level)
      if game.game_type == 'linear' && last_level? ||
          game.game_type == 'panic' && !closed?(level) &&
              closed_levels.count == game.levels.count - 1 ||
          game.game_type == 'selected' && last_level_selected?(team_id)
        closed_levels << level.id
        set_finish_time(get_finish_time(time_finish))
      else
        update_current_level_entered_at(time_finish)
        closed_levels << level.id
        # reset_answered_questions unless game.game_type == 'panic'
        # reset_answered_bonuses unless game.game_type == 'panic'
        if game.game_type == 'linear'
          self.current_level = level.next
        elsif game.game_type == 'selected'
          self.current_level = next_selected_level(level, team_id)
        end
      end
      game_bonus_options = {
          game_id: game_id,
          level_id: level.id,
          team_id: team_id,
          award: - (level.autocomplete_penalty || 0),
          user_id: user_id,
          reason: 'штраф за автоперехід',
          description: ''
      }
      if level.is_autocomplete_penalty? && !level.autocomplete_penalty.zero? &&
          GameBonus.where(game_bonus_options).count.zero?
        GameBonus.create!(game_bonus_options)
      end
      ClosedLevel.close_level!(game_id, level.id, team_id, user_id, time_start, time_finish, true)
    end
    save!
  end

  def use_penalty_hint!(level_id, penalty_hint_id, user_id)
    level = Level.find(level_id)
    penalty_hint = level.penalty_hints.find(penalty_hint_id)
    unless self.penalty_hints.include?(penalty_hint.id)
      unless penalty_hint.nil?
        GameBonus.create!(game_id: game_id, level_id: level_id, team_id: team_id, award: - penalty_hint.penalty, user_id: user_id, reason: 'за штрафну підказку', description: '') unless penalty_hint.penalty.zero?
        # self.sum_bonuses -= penalty_hint.penalty
        penalty_hints << penalty_hint.id
        save!
        PrivatePub.publish_to "/game_passings/#{self.id}/#{level.id}/penalty_hints", hint: {
            id: penalty_hint.id,
            name: penalty_hint.name,
            text: penalty_hint.text,
            used: true,
            penalty: penalty_hint.penalty
        }
      end
    end

  end

  def miss_bonus!(level_id, bonus_id)
    lock!
    level = Level.find(level_id)
    bonus = level.bonuses.find(bonus_id)
    missed_bonuses << bonus_id unless self.missed_bonuses.include?(bonus_id) || bonus.nil?
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

  protected

  def last_level?
    self.current_level.next.nil?
  end

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

  def seconds_to_string(s)
    sign = s < 0 ? '-' : ''

    # d = days, h = hours, m = minutes, s = seconds
    m = (s.abs / 60).floor
    s = s.abs % 60
    h = (m / 60).floor
    m = m % 60
    d = (h / 24).floor
    h = h % 24

    output = sign
    output << "#{d} дн " if (d > 0)
    output << "#{h} г " if (h > 0)
    output << "#{m} хв " if (m > 0)
    output << "#{s} с" if (s > 0)

    output
  end
end
