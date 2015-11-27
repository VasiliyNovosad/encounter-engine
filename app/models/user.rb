class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :confirmable, :validatable

  belongs_to :team

  has_many :created_games, class_name: 'Game', foreign_key: 'author_id'

  before_save { self.email = email.downcase }
  # before_create :create_remember_token

  validates :nickname, presence: true, uniqueness: true

  validates_format_of :icq_number, with: /\A(\d{6,9})?\Z/, message: 'Невірний номер ICQ', on: :update

  validates_format_of :jabber_id, with: /\A(([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,}))?\Z/i,
                                  message: 'Невірний Jabber ID', on: :update

  validates_format_of :date_of_birth,
                      with: /\A(^[0-9]{4}-(((0[13578]|(10|12))-(0[1-9]|[1-2][0-9]|3[0-1]))|(02-(0[1-9]|[1-2][0-9]))|((0[469]|11)-(0[1-9]|[1-2][0-9]|30)))$)?\Z/i,
                      message: 'Невірна дата народження. Використовуйте формат РРРР-ММ-ДД', on: :update

  validates_format_of :phone_number, with: /\A(\d+\b.*)?\Z/i,
                                     message: 'Невірний номер телефону. Використовуйте лише цифри', on: :update

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
    game.author.id == id
  end

  # def self.new_remember_token
  #   SecureRandom.urlsafe_base64
  # end

  # def self.digest(token)
  #   Digest::SHA1.hexdigest(token.to_s)
  # end

  # private

  # def create_remember_token
  #   self.remember_token = User.digest(User.new_remember_token)
  # end
end
