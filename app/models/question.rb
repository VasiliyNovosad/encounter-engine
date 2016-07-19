class Question < ActiveRecord::Base
  belongs_to :level
  belongs_to :team
  has_many :answers, dependent: :destroy
  acts_as_list scope: :level

  validates :name, presence: { message: 'Не введено назву сектора' }
  validates :name, uniqueness: { scope: :level, message: 'Сектор з такою назвою уже є на даному рівні' }

  before_validation :set_name

  def correct_answer=(answer)
    if answers.empty?
      answers.build(value: answer)
    else
      answers.first.value = answer
    end
  end

  def correct_answer
    answers.empty? ? nil : answers.first.value
  end

  def matches_any_answer(answer_value)
    require 'ee_strings.rb'
    answers.any? { |answer| answer.value.to_s.upcase_utf8_cyr == answer_value.to_s.upcase_utf8_cyr }
  end

  def set_name
    self.name ||= 'Сектор 1'
  end
end
