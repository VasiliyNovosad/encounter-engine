class TeamRequest < ActiveRecord::Base
  belongs_to :team
  belongs_to :user

  scope :for, ->(team) { where(team_id: team.id) }

  attr_accessor :team_name

  validates_presence_of :team,
                        message: 'Команди з такою назвою не існує'

  validates_presence_of :team_name,
                        message: 'Не введено назву команди'

  validates_uniqueness_of :team_id,
                          scope: [:user_id],
                          message: 'Запит на вступ в дану команду уже відправлено і його ще не прийнято'

  validate :recepient_is_not_captain_of_any_team
  validate :recepient_is_not_member_of_team

  before_validation :find_team

  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :to_team, ->(team) { where(team_id: team.id) }

  protected

  def find_team
    require 'ee_strings.rb'
    team = Team.by_name(team_name.downcase_utf8_cyr)
    self.team = team.first if team && team.count > 0
  end

  def recepient_is_not_captain_of_any_team
    errors.add(:base, 'Користувач уже є членом даної команди') if user && user.captain?
  end

  def recepient_is_not_member_of_team
    errors.add(:base, 'Ви уже є членом даної команди') if user && user.team == team
  end
end