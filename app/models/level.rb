class Level < ActiveRecord::Base
  belongs_to :game
  acts_as_list scope: :game

  has_many :questions, -> { order(:position) }, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :hints, -> { order(:delay) }, dependent: :destroy
  has_many :tasks, dependent: :destroy

  # validates :text, presence: { message: 'Не введено текст завдання' }, if: :tasks_not_presence?
  validates :game, presence: true
  validates :name, presence: { message: 'Не введено назву завдання' }
  validates :name, uniqueness: { scope: :game, message: 'Рівень з такою назвою уже є в даній грі' }

  scope :of_game, ->(game) { where(game_id: game.id).order(:position) }

  def next
    lower_item
  end

  def correct_answer=(answer)
    questions.build(correct_answer: answer)
  end

  def correct_answer
    questions.empty? ? nil : questions.first.answers.first.value
  end

  def multi_question?(team_id)
    team_questions(team_id).count > 1
  end

  def find_questions_by_answer(answer_value, team_id)
    require 'ee_strings.rb'
    team_questions(team_id).select do |question|
      question.team_answers(team_id).any? { |answer| answer.value.to_s.upcase_utf8_cyr == answer_value.to_s.upcase_utf8_cyr }
    end
  end

  def complete_later_minutes
    complete_later.nil? ? nil : complete_later / 60
  end

  def complete_later_minutes=(value)
    self.complete_later = value.to_i * 60
  end

  def tasks_not_presence?
    tasks.nil? || tasks.count == 0
  end

  def team_questions(team_id)
    questions.where("team_id IS NULL OR team_id = #{team_id}")
  end

  def team_task(team_id)
    team_tasks = tasks.where(team_id: team_id).first
    unless team_tasks.nil?
      return team_tasks.text
    end
    team_tasks = tasks.where('team_id IS NULL').first
    unless team_tasks.nil?
      return team_tasks.text
    end
    text
  end

end
