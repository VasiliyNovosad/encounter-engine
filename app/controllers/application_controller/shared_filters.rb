# -*- coding: utf-8 -*-
class ApplicationController
  module SharedFilters
    protected

    def ensure_authenticated
      unless signed_in?
        raise "Нужно залогиниться, чтобы видеть эту страницу"
      end
    end

    def ensure_team_member
      unless current_user.member_of_any_team?
        raise "Вы не авторизованы для посещения этой страницы"
      end
    end

    def ensure_team_captain
      unless current_user.captain?
        raise "Вы должны быть капитаном чтобы выполнить это действие"
      end
    end

    def ensure_author
      unless signed_in? and @current_user.author_of?(@game)
        raise "Вы должны быть автором игры, чтобы видеть эту страницу"
      end
    end

    def ensure_game_was_not_started
      raise "Нельзя редактировать игру после её начала" if @game.started?
    end
  end
end
