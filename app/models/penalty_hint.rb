class PenaltyHint < ApplicationRecord
  belongs_to :level
  belongs_to :team

  scope :of_team, ->(team_id) { where('team_id IS NULL OR team_id = ?', team_id) }

  def time_to_delay(current_level_entered_at, current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    (current_level_entered_at - current_time).to_i + (self.delay_for || 0) if self.is_delayed?
  end
end
