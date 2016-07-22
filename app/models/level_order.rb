class LevelOrder < ActiveRecord::Base
  belongs_to :game
  belongs_to :team
  acts_as_list scope: [:game_id, :team_id, :level_id]

  scope :of_game, ->(game) { where(game_id: game.id) }
  scope :of_team, ->(team) { where(team_id: team.id).order(:position) }

  def self.of(game, team)
    of_game(game).of_team(team)
  end

end
