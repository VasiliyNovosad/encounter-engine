class Question < ActiveRecord::Base
  belongs_to :level
  has_many :answers, dependent: :destroy

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
end
