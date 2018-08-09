class PenaltyHint < ActiveRecord::Base
  belongs_to :level
  belongs_to :team

  def time_to_delay(current_level_entered_at, current_time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    (current_level_entered_at - current_time).to_i + (self.delay_for || 0) if self.is_delayed?
  end
end
