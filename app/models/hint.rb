class Hint < ApplicationRecord
  belongs_to :level
  belongs_to :team

  scope :of_team, ->(team_id) { where('team_id IS NULL OR team_id = ?', team_id) }

  def delay_in_minutes
    delay.nil? ? nil : delay / 60
  end

  def delay_in_minutes=(value)
    self.delay = value.to_i * 60
  end

  def ready_to_show?(current_level_entered_at)
    seconds_passed = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time - current_level_entered_at
    seconds_passed >= delay
  end

  def available_in(current_level_entered_at)
    (current_level_entered_at - Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time).to_i + delay
  end
end
