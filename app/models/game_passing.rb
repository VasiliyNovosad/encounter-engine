class GamePassing < ActiveRecord::Base
  serialize :answered_questions
  default_value_for :answered_questions, []
  serialize :closed_levels
  default_value_for :closed_levels, []

  belongs_to :team
  belongs_to :game
  belongs_to :current_level, class_name: 'Level'

  scope :of_game, ->(game) { where(game_id: game.id) }
  scope :of_team, ->(team) { where(team_id: team.id) }
  scope :ended_by_author, -> { where(status: 'ended').order('current_level_id DESC') }
  scope :exited, -> { where(status: 'exited').order('finished_at DESC') }
  scope :finished, -> { where('finished_at IS NOT NULL').order('finished_at ASC') }
  scope :finished_before, ->(time) { where('finished_at < ?', time) }

  before_create :update_current_level_entered_at

  def self.of(team, game)
    of_team(team).of_game(game).first
  end

  def check_answer!(answer, level)
    answer.strip!

    if correct_answer?(answer, level)
      answered_question = level.find_questions_by_answer(answer)
      pass_question!(answered_question)
      pass_level!(level) if all_questions_answered?(level)
      true
    else
      false
    end
  end

  def pass_question!(questions)
    questions.each { |question| answered_questions << question }
    save!
  end

  def pass_level!(level)
    if last_level? && game.game_type == 'linear' ||
       game.game_type == 'panic' && !closed?(level) && closed_levels.count == game.levels.count - 1
      set_finish_time
    else
      update_current_level_entered_at
    end
    closed_levels << level.id unless closed? level
    reset_answered_questions
    self.current_level = self.current_level.next unless game.game_type == 'panic'
    save!
  end

  def closed?(level)
    closed_levels.include? level.id
  end

  def finished?
    !!finished_at
  end

  def hints_to_show(level = self.current_level)
    level.hints.where("team_id IS NULL OR team_id = #{team.id}").select { |hint| hint.ready_to_show?(current_level_entered_at) }
  end

  def upcoming_hints(level = self.current_level)
    level.hints.where("team_id IS NULL OR team_id = #{team.id}").select { |hint| !hint.ready_to_show?(current_level_entered_at) }
  end

  def correct_answer?(answer, level)
    unanswered_questions(level).any? { |question| question.matches_any_answer(answer, team.id) }
  end

  def time_at_level
    difference = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S").to_time - current_level_entered_at
    hours, minutes, seconds = seconds_fraction_to_time(difference)
    '%02d:%02d:%02d' % [hours, minutes, seconds]
  end

  def unanswered_questions(level)
    level.team_questions(team.id) - answered_questions
  end

  def all_questions_answered?(level)
    (level.team_questions(team.id) - answered_questions).empty?
  end

  def exit!
    self.finished_at = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S").to_time
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

  def autocomplete_level!(level)
    lock!
    if last_level?
      set_finish_time
    else
      update_current_level_entered_at
      reset_answered_questions
      self.current_level = self.current_level.next
    end
    save!
  end

  protected

  def last_level?
    self.current_level.next.nil?
  end

  def update_current_level_entered_at
    self.current_level_entered_at = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S").to_time
  end

  def set_finish_time
    self.finished_at = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S").to_time
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
