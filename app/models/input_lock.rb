class InputLock < ActiveRecord::Base
  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_level, ->(level_id) { where(level_id: level_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }
  scope :of_user, ->(user_id) { where(user_id: user_id) }
end