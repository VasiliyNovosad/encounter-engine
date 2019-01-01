class BonusAnswer < ActiveRecord::Base
  belongs_to :bonus
  belongs_to :team

  before_save :strip_spaces

  validates_presence_of :value, message: 'Не введено варіант коду'

  validates_uniqueness_of :value, scope: [:bonus_id], message: 'Такий код вже є в даному бонусі'

  scope :of_bonus, ->(bonus_id) { where(bonus_id: bonus_id) }
  scope :of_team, ->(team_id) { where('team_id IS NULL OR team_id = ?', team_id) }

  protected

  def strip_spaces
    value.strip!
  end

end