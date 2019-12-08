class Level < ApplicationRecord
  belongs_to :game
  acts_as_list scope: :game

  has_many :questions, -> { order(:position) }, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :hints, -> { order(:delay) }, dependent: :destroy
  has_many :penalty_hints, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :game_bonuses, class_name: 'GameBonus'
  has_and_belongs_to_many :messages, join_table: 'messages_levels'
  has_and_belongs_to_many :bonuses, -> { order(:position) }, join_table: 'levels_bonuses'


  # validates :text, presence: { message: 'Не введено текст завдання' }, if: :tasks_not_presence?
  validates :game, presence: true
  validates :name, presence: { message: 'Не введено назву завдання' }
  # validates :name, uniqueness: { scope: :game, message: 'Рівень з такою назвою уже є в даній грі' }

  scope :of_game, ->(game_id) { where(game_id: game_id).order(:position) }

  delegate :starts_at, to: :game, prefix: true

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
    team_questions(team_id).size > 1
  end

  def has_bonuses?(team_id)
    team_bonuses(team_id).size > 0
  end

  def find_questions_by_answer(answer_value, team_id)
    team_questions(team_id).includes(:answers).select do |question|
      question.answers.select { |ans| ans.team_id.nil? || ans.team_id == team_id }.any? do |ans|
        ans.value.mb_chars.downcase.to_s == answer_value.mb_chars.downcase.to_s
      end
    end
  end

  def find_bonuses_by_answer(answer_value, team_id)
    team_bonuses(team_id).includes(:bonus_answers).select do |bonus|
      bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == team_id }.any? do |ans|
        ans.value.mb_chars.downcase.to_s == answer_value.mb_chars.downcase.to_s
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
    tasks.nil? || tasks.size == 0
  end

  def team_questions(team_id)
    questions.of_team(team_id)
  end

  def team_penalty_hints(team_id)
    penalty_hints.of_team(team_id)
  end

  def team_tasks(team_id)
    tasks.of_team(team_id)
  end

  def team_bonuses(team_id)
    bonuses.of_team(team_id)
  end

  def check_sectors_for_close
    self.sectors_for_close = questions.size if sectors_for_close > questions.size
  end

  def dismiss!(user_id)
    closed_levels = ClosedLevel.where(game_id: game_id, level_id: id)
    team_bonuses = GameBonus.select('team_id, SUM(award) AS sum_award').where(game_id: game_id, level_id: id).group(:team_id).to_a.group_by { |bonus| bonus.team_id}
    closed_levels.each do |closed_level|
      GameBonus.create(
        game_id: closed_level.game_id,
        level_id: closed_level.level_id,
        team_id: closed_level.team_id,
        award: closed_level.closed_at - closed_level.started_at - (team_bonuses[closed_level.team_id].nil? ? 0 : team_bonuses[closed_level.team_id].first[:sum_award]),
        user_id: user_id,
        reason: 'зняття рівня',
        description: ''
      )
    end
    self.dismissed = true
    save!
  end

  def undismiss!
    game_bonuses = GameBonus.where(game_id: game_id, level_id: id, reason: 'зняття рівня')
    game_bonuses.delete_all
    self.dismissed = false
    save!
  end

end
