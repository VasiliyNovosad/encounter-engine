module LogsHelper
  def correct_answer_by_level_id?(answer, level_id, team_id)
    level = Level.find(level_id)
    correct_answer_by_level?(answer.downcase, level, team_id)
  end

  def correct_answer_by_level?(answer, level, team_id)
    answer == 'timeout' ||
    level.team_questions(team_id).any? { |question| question.matches_any_answer(answer, team_id) } ||
    level.team_bonuses(team_id).any? { |bonus| bonus.matches_any_answer(answer, team_id) }
  end
end
