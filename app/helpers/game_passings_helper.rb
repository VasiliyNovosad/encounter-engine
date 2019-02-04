module GamePassingsHelper
  def answer_posted?
    !@answer.nil?
  end

  def answer_was_correct?
    !!@answer_was_correct
  end

  def game_levels_list(game)
    game.levels.map do |game_level|
      if game_level == @level
        "#{game_level.position}. #{game_level.name}"
      else
        "<a class=\"#{(@game_passing.closed?(game_level) ? 'closedlevel' : 'openedlevel')}\" href=\"/play/#{game.id}?level=#{game_level.position}\">#{game_level.position}. #{game_level.name}</a>"
      end
    end.join(', ')
  end
end
