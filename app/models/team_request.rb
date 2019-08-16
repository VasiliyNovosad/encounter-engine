class TeamRequest < ApplicationRecord
  belongs_to :team
  belongs_to :user

  scope :for, ->(team_id) { where(team_id: team_id) }

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

  protected

  def find_team
    require 'ee_strings.rb'
    team = Team.by_name(team_name.downcase_utf8_cyr).where(team_type: 'multy')
    self.team = team.first if team && team.count > 0
  end

  def recepient_is_not_captain_of_any_team
    errors.add(:base, 'Користувач є капітаном певної команди') if user&.captain?
  end

  def recepient_is_not_member_of_team
    errors.add(:base, 'Ви уже є членом даної команди') if user && user.team == team
  end
end
