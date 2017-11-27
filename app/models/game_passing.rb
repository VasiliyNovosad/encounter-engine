class GamePassing < ActiveRecord::Base
  require 'ee_strings.rb'

  serialize :answered_questions
  default_value_for :answered_questions, []
  serialize :answered_bonuses
  default_value_for :answered_bonuses, []
  serialize :closed_levels
  default_value_for :closed_levels, []

  belongs_to :team
  belongs_to :game
  belongs_to :current_level, class_name: 'Level'

  scope :of_game, ->(game) { where(game_id: game.id) }
  scope :of_team, ->(team) { where(team_id: team.id) }
  scope :ended_by_author, -> { where(status: 'ended').order('current_level_id DESC') }
  scope :exited, -> { where(status: 'exited').order('finished_at DESC') }
  scope :finished, -> { where('finished_at IS NOT NULL').order("(finished_at - sum_bonuses * interval '1 second') ASC") }
  scope :finished_before, ->(time) { where('finished_at < ?', time) }

  before_create :update_current_level_entered_at

  def self.of(team, game)
    of_team(team).of_game(game).first
  end

  def check_answer!(answer, level, team_id, time)
    answer.strip!
    is_correct_answer = false
    is_correct_bonus_answer = false

    if correct_bonus_answer?(answer, level, team_id)
      answered_bonus = level.find_bonuses_by_answer(answer, team_id)
      pass_bonus!(answered_bonus)
      is_correct_bonus_answer = true
    end
    if correct_answer?(answer, level, team_id)
      answered_question = level.find_questions_by_answer(answer, team_id)
      pass_question!(answered_question)
      pass_level!(level, team_id, time) if all_questions_answered?(level, team_id)
      is_correct_answer = true
    end
    is_correct_bonus_answer || is_correct_answer
  end

  def pass_question!(questions)
    changed = false
    questions.each do |question|
      unless answered_questions.include? question.id
        answered_questions << question.id
        changed = true
      end
    end
    save! if changed
  end

  def pass_bonus!(bonuses)
    changed = false
    bonuses.each do |bonus|
      unless answered_bonuses.include? bonus.id
        answered_bonuses << bonus.id
        self.sum_bonuses = self.sum_bonuses + bonus.award_time
        changed = true
      end
    end
    save! if changed
  end

  def pass_level!(level, team_id, time)
    unless closed?(level)
      if game.game_type == 'linear' && last_level? ||
       game.game_type == 'panic' && !closed?(level) &&
       closed_levels.count == game.levels.count - 1 ||
       game.game_type == 'selected' && last_level_selected?(team_id)
        closed_levels << level.id
        set_finish_time(time)
      else
        update_current_level_entered_at(time)
        closed_levels << level.id
        reset_answered_questions
        if game.game_type == 'linear'
          self.current_level = self.current_level.next
        elsif game.game_type == 'selected'
          self.current_level = next_selected_level(team_id)
        end
      end
      save!
    end
  end

  def closed?(level)
    closed_levels.include? level.id
  end

  def finished?
    !!finished_at
  end

  def hints_to_show(team_id, level = self.current_level)
    level.hints.where("team_id IS NULL OR team_id = #{team_id}").select { |hint| hint.ready_to_show?(current_level_entered_at) }
  end

  def upcoming_hints(team_id, level = self.current_level)
    level.hints.where("team_id IS NULL OR team_id = #{team_id}").select { |hint| !hint.ready_to_show?(current_level_entered_at) }
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
    level.team_questions(team_id) - Question.where(id: answered_questions)
  end

  def all_questions_answered?(level, team_id)
    (level.team_questions(team_id) - Question.where(id: answered_questions)).empty?
  end

  def unanswered_bonuses(level, team_id)
    level.team_bonuses(team_id) - Bonus.where(id: answered_bonuses)
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

  def autocomplete_level!(level, team_id)
    # this.with_lock do
      unless closed? level
        lock!
        if game.game_type == 'linear' && last_level? ||
            game.game_type == 'selected' && last_level_selected?(team_id)
          closed_levels << level.id
          set_finish_time(current_level_entered_at + level.complete_later)
        else
          update_current_level_entered_at(current_level_entered_at + level.complete_later)
          closed_levels << level.id
          reset_answered_questions
          if game.game_type == 'linear'
            self.current_level = self.current_level.next
          elsif game.game_type == 'selected'
            self.current_level = next_selected_level(team_id)
          end
        end
        save!
      end
    # end
  end

  def current_level_position(team_id)
    LevelOrder.of(game, Team.find_by_id(team_id)).where(level_id: current_level.id).first.position
  end

  protected

  def last_level?
    self.current_level.next.nil?
  end

  def last_level_selected?(team_id)
    level_position = LevelOrder.of(game, Team.find_by_id(team_id)).where(level_id: current_level.id).first.position
    LevelOrder.of(game, Team.find_by_id(team_id)).where(position: level_position + 1).first.nil?
  end

  def next_selected_level(team_id)
    level_position = LevelOrder.of(game, Team.find_by_id(team_id)).where(level_id: current_level.id).first.position
    Level.find_by_id(LevelOrder.of(game, Team.find_by_id(team_id)).where(position: level_position + 1).first.level_id)
  end

  def update_current_level_entered_at(time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    self.current_level_entered_at = time
  end

  def set_finish_time(time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    self.finished_at = time
  end

  def reset_answered_questions
    answered_questions.clear
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
end
