class GamePassingsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "game_passings_#{params['game_passing_id']}_#{params['level_id']}_#{params['user_id']}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
