module GamePassingsHelper
  def answer_posted?
    !!@answer
  end

  def answer_was_correct?
    !!@answer_was_correct
  end

  def game_levels_list(game)
    game.levels.map do |game_level|
      level_position = game_level.position
      level_name = game_level.name
      if game_level == @level
        "#{level_position}. #{level_name}"
      else
        "<a class=\"#{(@game_passing.closed?(game_level) ? 'closedlevel' : 'openedlevel')}\" href=\"/play/#{game.id}?level=#{level_position}\">#{level_position}. #{level_name}</a>"
      end
    end.join(', ')
  end
end
