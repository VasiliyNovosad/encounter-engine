class Hint < ActiveRecord::Base
  belongs_to :level
  belongs_to :team

  def delay_in_minutes
    delay.nil? ? nil : delay / 60
  end

  def delay_in_minutes=(value)
    self.delay = value.to_i * 60
  end

  def ready_to_show?(current_level_entered_at)
    seconds_passed = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S").to_time - current_level_entered_at
    seconds_passed >= delay
  end

  def available_in(current_level_entered_at)
    (current_level_entered_at - Time.zone.now.strftime("%d.%m.%Y %H:%M:%S").to_time).to_i + delay
  end
end
