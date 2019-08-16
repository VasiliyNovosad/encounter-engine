class Result < ApplicationRecord
  belongs_to :game
  belongs_to :team
  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }
end
