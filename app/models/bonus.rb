class Bonus < ActiveRecord::Base
  has_and_belongs_to_many :levels, join_table: 'levels_bonuses'
  belongs_to :team
  belongs_to :game
  has_many :bonus_answers, dependent: :destroy
  acts_as_list scope: :game_id

  accepts_nested_attributes_for :bonus_answers, reject_if: :all_blank, allow_destroy: true

  validates :name, presence: { message: 'Не введено назву бонуса' }

  before_validation :set_name

  scope :of_team, ->(team_id) { where('team_id IS NULL OR team_id = ?', team_id) }

  def correct_answer=(answer)
    if bonus_answers.empty?
      bonus_answers.build(value: answer, team_id: team.nil? ? nil : team.id)
    else
      bonus_answers.first.value = answer
    end
  end

  def correct_answer
    bonus_answers.empty? ? nil : bonus_answers.first.value
  end

  def matches_any_answer(answer_value, team_id)
    require 'ee_strings.rb'
    team_answers(team_id).any? { |answer| answer.value.to_s.upcase_utf8_cyr == answer_value.to_s.upcase_utf8_cyr }
  end

  def set_name
    self.name ||= 'Бонус 1'
  end

  def team_answers(team_id)
    bonus_answers.where("team_id IS NULL OR team_id = #{team_id}")
  end

  def team_correct_answer(team_id)
    team_answers(team_id).empty? ? nil : team_answers(team_id).first.value
  end

  def ready_to_show?(current_level_entered_at, current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    is_absolute_limited? && (valid_from.nil? || current_time >= valid_from) &&
        (valid_to.nil? || current_time <= valid_to) ||
          is_delayed? && current_time - current_level_entered_at >= delay_for

  end

  def time_to_miss(current_level_entered_at, current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    result = nil
    result ||= (self.valid_to - current_time).to_i if self.is_absolute_limited? && !self.valid_to.nil?
    result ||= (self.valid_for || 0) - (current_time - self.valid_from).to_i if self.is_absolute_limited? && self.valid_to.nil? && !self.valid_from.nil? && self.is_relative_limited?
    result ||= (self.valid_for || 0) + (self.delay_for || 0) - (current_time - current_level_entered_at).to_i if !self.is_absolute_limited? && self.is_delayed? && self.is_relative_limited?
    result ||= (self.valid_for || 0) - (current_time - current_level_entered_at).to_i if !self.is_absolute_limited? && !self.is_delayed? && self.is_relative_limited?
    result
  end

  def time_to_delay(current_level_entered_at, current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    result = nil
    result ||= (self.valid_from - current_time).to_i if self.is_absolute_limited? && !self.valid_from.nil?
    result ||= (current_level_entered_at - current_time).to_i + (self.delay_for || 0) if (!self.is_absolute_limited? || self.valid_from.nil?) && self.is_delayed?
    result
  end

  def is_delayed_now?(current_level_entered_at, current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    (self.is_absolute_limited? && !self.valid_from.nil? || self.is_delayed?) &&
            time_to_delay(current_level_entered_at, current_time) > 0
  end

  def is_limited_now?(current_level_entered_at, current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    (self.is_absolute_limited? && !self.valid_to.nil? || self.is_relative_limited) # && time_to_miss(current_level_entered_at, current_time) > 0
  end

end