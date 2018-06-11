class GameBonus < ActiveRecord::Base
  belongs_to :game
  belongs_to :team
  belongs_to :level
  belongs_to :user


  scope :of_game, ->(game) { where(game_id: game.id) }
  scope :of_team, ->(team) { where(team_id: team.id) }

  def self.of(team, game)
    of_team(team).of_game(game).first
  end

end