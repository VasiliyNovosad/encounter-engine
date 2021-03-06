class GameEntry < ApplicationRecord
  belongs_to :game
  belongs_to :team

  validates_presence_of :game, message: 'Не выбрано гру'
  validates_presence_of :team_id, message: 'Не вказано команду'
  # validates :team_id, uniqueness: { scope: :game, message: 'Заявка на цю гру уже була подана' }

  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }
  scope :with_status, ->(status) { where(status: status) }

  def self.of(team_id, game_id)
    of_team(team_id).of_game(game_id).first
  end

  def reopen!
    self.status = 'new'
    save!
  end

  def accept!
    self.status = 'accepted'
    save!
  end

  def reject!
    self.status = 'rejected'
    save!
  end

  def recall!
    self.status = 'recalled'
    save!
  end

  def cancel!
    self.status = 'canceled'
    save!
  end
end
