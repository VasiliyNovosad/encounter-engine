# -*- coding: utf-8 -*-
class ApplicationController
  module SharedFilters
    protected

    def ensure_authenticated
      fail 'Нужно залогиниться, чтобы видеть эту страницу' unless signed_in?
    end

    def ensure_team_member
      unless current_user.member_of_any_team?
        fail 'Вы не авторизованы для посещения этой страницы'
      end
    end

    def ensure_team_captain
      unless current_user.captain?
        fail 'Вы должны быть капитаном чтобы выполнить это действие'
      end
    end

    def ensure_author
      unless signed_in? && @current_user.author_of?(@game)
        fail 'Вы должны быть автором игры, чтобы видеть эту страницу'
      end
    end

    def ensure_game_was_not_started
      fail 'Нельзя редактировать игру после её начала' if @game.started?
    end
  end
end
