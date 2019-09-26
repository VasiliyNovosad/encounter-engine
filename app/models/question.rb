class Question < ActiveRecord::Base
  belongs_to :level
  belongs_to :team
  has_many :answers, dependent: :destroy
  has_and_belongs_to_many :game_passings, join_table: 'game_passings_questions'
  attr_accessor :answers_list

  acts_as_list scope: [:level_id, :team_id]

  accepts_nested_attributes_for :answers, reject_if: :all_blank, allow_destroy: true

  validates :name, presence: { message: 'Не введено назву сектора' }
  # validates :name, uniqueness: { scope: [:level, :team], message: 'Сектор з такою назвою уже є на даному рівні' }

  before_validation :set_name

  scope :of_team, ->(team_id) { where('team_id IS NULL OR team_id = ?', team_id) }

  def correct_answer=(answer)
    if answers.empty?
      answers.build(value: answer, team_id: team_id)
    else
      answers.first.value = answer
    end
  end

  def correct_answer
    answers.empty? ? nil : answers.first.value
  end

  def matches_any_answer(answer_value, team_id)
    require 'ee_strings.rb'
    team_answers(team_id).any? { |answer| answer.value.to_s.downcase_utf8_cyr == answer_value.to_s.downcase_utf8_cyr }
  end

  def set_name
    self.name ||= 'Сектор 1'
  end

  def team_answers(team_id)
    answers.where("team_id IS NULL OR team_id = #{team_id}")
  end

  def team_correct_answer(team_id)
    team_answers(team_id).empty? ? nil : team_answers(team_id).first.value
  end
end
