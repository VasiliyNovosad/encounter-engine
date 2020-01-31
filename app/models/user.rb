class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :session_limitable,
         :recoverable, :rememberable, :confirmable, :validatable,
         :omniauthable, omniauth_providers: [:facebook]

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

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session['devise.facebook_data'] && session['devise.facebook_data']['extra']['raw_info']
        user.email = data['email'] if user.email.blank?
        user.nickname = data['name'] if user.nickname.blank?
      end
    end
  end

  def self.from_omniauth(auth)
    if where(email: auth.info.email).exists?
      return_user = self.where(email: auth.info.email).first
      return_user.provider = auth.provider
      return_user.uid = auth.uid
      return_user.save
    else
      return_user = create do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.password = Devise.friendly_token[0, 20]
        user.nickname = auth.info.name
        user.email = auth.info.email
      end
    end

    return_user
  end

  # def forem_name
  #   nickname
  # end
end
