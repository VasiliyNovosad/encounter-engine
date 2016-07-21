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
end
