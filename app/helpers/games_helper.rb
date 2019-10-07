module GamesHelper
  def game_with_personal?
    levels = @game.levels
    tasks = 0
    hints = 0
    questions = 0
    answers = 0
    levels.each do |level|
      unless level.tasks.count == 0
        level.tasks.each do |task|
          tasks += 1 unless task.team.nil?
        end
        level.hints.each do |hint|
          hints += 1 unless hint.team.nil?
        end
        level.questions.each do |question|
          questions += 1 unless question.team.nil?
          unless question.answers.count == 0
            question.answers.each do |answer|
              answers += 1 unless answer.team.nil?
            end
          end
        end
      end
    end
    tasks + hints + questions + answers > 0
  end

  def get_images(game_description)
    require 'nokogiri'
    doc = Nokogiri::HTML(game_description)
    doc.xpath("//img").map { |img| img['src'] }
  end

  def telegram_user(telegram)
    if telegram.nil? || telegram == ''
      nil
    else
      telegram[0] == '@' ? telegram[1..-1] : telegram
    end
  end

  def game_start_date(game)
    if game.starts_at.nil?
      'Дата початку гри ще не призначена'
    else
      "<em>Початок гри</em>: #{(game.is_testing? ? game.test_date : game.starts_at).strftime('%H:%M %d.%m.%Y')}".html_safe
    end
  end

  def hide_stat?(game, team)
    return false unless game.hide_stat?

    game_passing = GamePassing.of(team.id, game.id)
    return true if game_passing.nil?

    return false unless game_passing.finished_at.nil?

    game.hide_stat_type == 'all' || game_passing.current_level.position <= game.hide_stat_level
  end
end
