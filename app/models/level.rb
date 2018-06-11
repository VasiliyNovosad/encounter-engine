class Level < ActiveRecord::Base
  belongs_to :game
  acts_as_list scope: :game

  has_many :questions, -> { order(:position) }, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :hints, -> { order(:delay) }, dependent: :destroy
  has_many :penalty_hints, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :bonuses, -> { order(:position) }, dependent: :destroy
  has_many :game_bonuses, class_name: 'GameBonus'

  # validates :text, presence: { message: 'Не введено текст завдання' }, if: :tasks_not_presence?
  validates :game, presence: true
  validates :name, presence: { message: 'Не введено назву завдання' }
  # validates :name, uniqueness: { scope: :game, message: 'Рівень з такою назвою уже є в даній грі' }

  scope :of_game, ->(game) { where(game_id: game.id).order(:position) }

  before_save :check_sectors_for_close

  def next
    lower_item
  end

  def correct_answer=(answer)
    questions.build(correct_answer: answer)
  end

  def correct_answer
    questions.empty? ? nil : questions.first.answers.first.value
  end

  def bonus_correct_answer=(answer)
    bonuses.build(correct_answer: answer)
  end

  def bonus_correct_answer
    bonuses.empty? ? nil : bonuses.first.bonus_answers.first.value
  end

  def multi_question?(team_id)
    team_questions(team_id).count > 1
  end

  def has_bonuses?(team_id)
    team_bonuses(team_id).count > 0
  end

  def find_questions_by_answer(answer_value, team_id)
    require 'ee_strings.rb'
    # team_questions(team_id).select do |question|
    #   question.team_answers(team_id).any? { |answer| answer.value.to_s.upcase_utf8_cyr == answer_value.to_s.upcase_utf8_cyr }
    # end
    team_questions(team_id).includes(:answers).select do |question|
      # bonus.matches_any_answer(answer, team_id)
      question.answers.select { |ans| ans.team_id.nil? || ans.team_id == team_id }.any? do |ans|
        ans.value.to_s.downcase_utf8_cyr == answer_value.to_s.downcase_utf8_cyr
      end
    end
  end

  def find_bonuses_by_answer(answer_value, team_id)
    require 'ee_strings.rb'
    # team_bonuses(team_id).select do |bonus|
    #   bonus.team_answers(team_id).any? { |answer| answer.value.to_s.upcase_utf8_cyr == answer_value.to_s.upcase_utf8_cyr }
    # end
    team_bonuses(team_id).includes(:bonus_answers).select do |bonus|
      # bonus.matches_any_answer(answer, team_id)
      bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == team_id }.any? do |ans|
        ans.value.to_s.downcase_utf8_cyr == answer_value.to_s.downcase_utf8_cyr
      end
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

  def team_penalty_hints(team_id)
    penalty_hints.where("team_id IS NULL OR team_id = #{team_id}")
  end

  def team_tasks(team_id)
    all_tasks = []
    team_tasks = tasks.where(team_id: team_id).to_a
    unless team_tasks.nil?
      all_tasks += team_tasks
    end
    team_tasks = tasks.where('team_id IS NULL').to_a
    unless team_tasks.nil?
      all_tasks += team_tasks
    end
    all_tasks
  end

  def team_bonuses(team_id)
    bonuses.where("team_id IS NULL OR team_id = #{team_id}")
  end

  def check_sectors_for_close
    self.sectors_for_close = questions.count if sectors_for_close > questions.count
  end

end
