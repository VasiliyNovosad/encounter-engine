class LevelOrder < ActiveRecord::Base
  belongs_to :game
  belongs_to :team

  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id).order(:position) }

  def self.of(game_id, team_id)
    of_game(game_id).of_team(team_id)
  end

end
