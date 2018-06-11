class GameBonus < ActiveRecord::Base
  belongs_to :game
  belongs_to :team
  belongs_to :level
  belongs_to :user


  scope :of_game, ->(game) { where(game_id: game.id) }
  scope :of_team, ->(team) { where(team_id: team.id) }
  scope :of_level, ->(level) { where(level_id: level.id) }

  def self.of(game, team, level)
    of_game(game).of_team(team).of_level(level).all
  end

end