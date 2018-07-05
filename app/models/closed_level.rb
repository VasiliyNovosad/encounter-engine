class ClosedLevel < ActiveRecord::Base
  belongs_to :user
  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }
  scope :of_level, ->(level_id) { where(level_id: level_id) }


  def self.close_level!(game_id, level_id, team_id, user_id, start_time, finish_time, timeout = false)
    closed_levels = of_game(game_id).of_level(level_id).of_team(team_id).count
    if closed_levels == 0
      self.create!(
          game_id: game_id,
          level_id: level_id,
          team_id: team_id,
          user_id: user_id,
          started_at: start_time,
          closed_at: finish_time,
          timeouted: timeout
      )
    end
  end
end
