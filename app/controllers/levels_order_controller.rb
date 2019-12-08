class LevelsOrderController < ApplicationController
  before_action :find_game

  def sort
    params[:level].each_with_index do |id, index|
      LevelOrder.where(game_id: @game.id, team_id: params[:team_id], level_id: id).update_all(position: index + 1)
    end

    head :ok
  end

  protected

  def find_game
    @game = Game.friendly.find(params[:game_id])
  end
end