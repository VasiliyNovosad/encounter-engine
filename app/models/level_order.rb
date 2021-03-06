class LevelOrder < ApplicationRecord
  belongs_to :game
  belongs_to :team
  acts_as_list scope: [:game, :team]
  validates :level_id, uniqueness: { scope: [:game, :team] }

  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }

  def self.of(game_id, team_id)
    of_game(game_id).of_team(team_id)
  end

end
