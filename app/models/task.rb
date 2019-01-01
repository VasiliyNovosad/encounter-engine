class Task < ActiveRecord::Base
  belongs_to :level
  belongs_to :team

  # validates :team, presence: true
  validates :team, uniqueness: { scope: :level, message: 'Вибрана команда уже має персональне завдання на даному рівні' }

  scope :of_team, ->(team_id) { where('team_id IS NULL OR team_id = ?', team_id) }
end