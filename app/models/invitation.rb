class Invitation < ApplicationRecord
  belongs_to :to_team, class_name: 'Team'
  belongs_to :for_user, class_name: 'User'

  scope :of, ->(user_id) { where(for_user_id: user_id) }

  attr_accessor :recepient_nickname

  validates_presence_of :for_user,
                        message: 'Користувач з таким іменем не існує'

  validates_presence_of :recepient_nickname,
                        message: "Не введено ім'я користувача"

  validates_uniqueness_of :for_user_id,
                          scope: [:to_team_id],
                          message: 'Запрошення даному користувачу уже відправлено і він ще не відповів'

  validate :recepient_is_not_member_of_team

  before_validation :find_user

  scope :for_user, ->(user_id) { where(for_user_id: user_id) }
  scope :to_team, ->(team_id) { where(to_team_id: team_id) }

  protected

  def find_user
    user = User.by_nickname(recepient_nickname.mb_chars.downcase.to_s)
    self.for_user = user.first if user && user.size.positive?
  end

  def recepient_is_not_member_of_team
    errors.add(:base, 'Користувач уже є членом даної команди') if for_user && for_user.team == to_team
  end
end
