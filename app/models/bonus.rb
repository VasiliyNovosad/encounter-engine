class Bonus < ActiveRecord::Base
  belongs_to :level
  belongs_to :team
  has_many :bonus_answers, dependent: :destroy
  acts_as_list scope: [:level_id, :team_id]

  accepts_nested_attributes_for :bonus_answers, reject_if: :all_blank, allow_destroy: true

  validates :name, presence: { message: 'Не введено назву бонуса' }

  before_validation :set_name

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

  def ready_to_show?(current_level_entered_at)
    is_relative_limited? && Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time - current_level_entered_at >= delay ||
        is_absolute_limited? && (valid_from.nil? || Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time >= valid_from) &&
            (valid_to.nil? || Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time <= valid_to)
  end

  def available_in(current_level_entered_at)
    # ToDo: to check if is_absolute_limit or is_relative_limit
    (current_level_entered_at - Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time).to_i + delay
  end

end