class Invitation < ActiveRecord::Base
  belongs_to :to_team, class_name: 'Team'
  belongs_to :for_user, class_name: 'User'

  scope :for, ->(user) { where(for_user_id: user.id) }

  attr_accessor :recepient_nickname

  validates_presence_of :for_user,
                        message: 'Користувач з таким іменем не існує'

  validates_presence_of :recepient_nickname,
                        message: "Не введено ім'я користувача"

  validates_uniqueness_of :for_user_id,
                          scope: [:to_team_id],
                          message: 'Запрошення даному користувачу уже відправлено і він ще не відповів'

  #validate :recepient_is_not_member_of_any_team

  before_validation :find_user

  scope :for_user, ->(user) { where(for_user_id: user.id) }
  scope :to_team, ->(team) { where(to_team_id: team.id) }

  protected

  def find_user
    self.for_user = User.find_by_nickname(recepient_nickname)
  end

  def recepient_is_not_member_of_any_team
    errors.add_to_base('Користувач уже є членом однієй із команд') if for_user && for_user.member_of_any_team?
  end
end
