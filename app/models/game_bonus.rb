class GameBonus < ActiveRecord::Base
  belongs_to :game
  belongs_to :team
  belongs_to :level
  belongs_to :user

  validates :reason, uniqueness: { scope: [:game, :team, :level, :description] }

  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }
  scope :of_level, ->(level_id) { where(level_id: level_id) }

  def self.of(game_id, team_id, level_id)
    of_game(game_id).of_team(team_id).of_level(level_id).all
  end

end