class Log < ActiveRecord::Base
  paginates_per 50

  belongs_to :game
  belongs_to :user

  scope :of_game, ->(game) { where(game_id: game.id) }
  scope :of_team, ->(team) { where(team_id: team.id) }
  scope :of_level, ->(level) { where(level_id: level.id) }
  scope :order_by_time, -> { order(:time) }
end
