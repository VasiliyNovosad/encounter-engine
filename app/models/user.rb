class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :session_limitable,
         :recoverable, :rememberable, :confirmable, :validatable

  belongs_to :team
  belongs_to :single_team, class_name: 'Team', foreign_key: 'single_team_id'

  has_many :created_games, class_name: 'Game', foreign_key: 'author_id'
  has_and_belongs_to_many :games, join_table: 'games_authors', foreign_key: 'author_id', association_foreign_key: 'game_id'
  has_many :logs
  has_many :game_bonuses, class_name: 'GameBonus'
  has_many :closed_levels, class_name: 'ClosedLevel'
  has_many :messages

  scope :by_nickname, ->(nickname) { where('lower(nickname) = ?', nickname) }

  before_save do
    self.email = email.downcase.strip
    self.nickname = nickname.strip
    if single_team_id.nil?
      new_team = Team.create!(name: self.nickname, team_type: 'single')
      self.single_team_id = new_team.id
    end
  end

  validates :nickname, presence: true
  validates_uniqueness_of :nickname, case_sensitive: false

  validates :phone_number, format: { with: /\A(\d+\b.*)?\Z/i, message: 'Невірний номер телефону. Використовуйте лише цифри'}, on: :update

  def member_of_any_team?
    !!team
  end

  def captain?
    member_of_any_team? && team.captain_id == id
  end

  def captain_of_team?(team)
    team.captain_id == id
  end

  def author_of?(game)
    game.author_id == id || game.author_ids.include?(id)
  end

  # def forem_name
  #   nickname
  # end
end
