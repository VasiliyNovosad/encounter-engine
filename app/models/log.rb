class Log < ActiveRecord::Base
  belongs_to :game
  belongs_to :user

  scope :of_game, ->(game) { where(game_id: game.id) }
  scope :of_team, ->(team) { where(team: team.name) }
  scope :of_level, ->(level) { where(level: level.name).order(:time) }
end
