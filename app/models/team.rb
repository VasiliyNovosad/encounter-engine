class Team < ActiveRecord::Base
  has_many :game_entries, class_name: 'GameEntry'
  has_many :members, class_name: 'User'
  belongs_to :captain, class_name: 'User'
  has_many :tasks
  has_many :hints
  has_many :penalty_hints
  has_many :questions
  has_many :answers
  has_many :level_orders

  scope :by_name, ->(name) { where('lower(name) = ?', name) }

  validates_uniqueness_of :name, message: 'Команда з такою назвою уже існує'

  validates_presence_of :name, message: 'Назва команди не повинна бути порожньою', on: :create

  before_save :adopt_captain

  def current_level_in(game)
    game_passing = GamePassing.of(self, game)
    game_passing.try(:current_level)
  end

  def finished?(game)
    game_passing = GamePassing.of(self, game)
    !!game_passing.try(:finished?)
  end

  protected

  def adopt_captain
    members << captain unless captain.nil? || members.include?(captain)
  end
end
