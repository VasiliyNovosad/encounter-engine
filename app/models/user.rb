class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :confirmable, :validatable

  belongs_to :team

  has_many :created_games, class_name: 'Game', foreign_key: 'author_id'
  has_and_belongs_to_many :games, join_table: 'games_authors', foreign_key: 'author_id', association_foreign_key: 'game_id'
  has_many :logs

  before_save { self.email = email.downcase }

  validates :nickname, presence: true, uniqueness: true

  validates :phone_number, format: { with: /\A(\d+\b.*)?\Z/i, message: 'Невірний номер телефону. Використовуйте лише цифри'}, on: :update

  def member_of_any_team?
    !!team
  end

  def captain?
    member_of_any_team? && team.captain.id == id
  end

  def captain_of_team?(team)
    team.captain.id == id
  end

  def author_of?(game)
    game.author.id == id || game.authors.map(&:id).include?(id)
  end
end
