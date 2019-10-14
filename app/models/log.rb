class Log < ActiveRecord::Base
  paginates_per 50

  belongs_to :game
  belongs_to :level
  belongs_to :team
  belongs_to :user

  scope :of_game, ->(game_id) { where(game_id: game_id) }
  scope :of_team, ->(team_id) { where(team_id: team_id) }
  scope :of_level, ->(level_id) { where(level_id: level_id) }
  scope :order_by_time, -> { order(:time) }

  delegate :nickname, to: :user, prefix: true

  def self.add(game_id, level_id, team_id, user_id, time, answer = 'timeout', answer_type = 3)
    Log.create!(
      game_id: game_id,
      level_id: level_id,
      team_id: team_id,
      user_id: user_id,
      time: time,
      answer: answer,
      answer_type: answer_type
    )
  end
end
