class BonusAnswer < ActiveRecord::Base
  belongs_to :bonus
  belongs_to :team

  before_save :strip_spaces

  validates_presence_of :value, message: 'Не введено варіант коду'

  validates_uniqueness_of :value, scope: [:bonus_id], message: 'Такий код вже є в даному бонусі'

  scope :of_bonus, ->(bonus) { where(bonus_id: bonus.id) }

  protected

  def strip_spaces
    value.strip!
  end

end