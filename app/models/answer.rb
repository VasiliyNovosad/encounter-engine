class Answer < ActiveRecord::Base
  belongs_to :question
  belongs_to :level

  before_save :strip_spaces
  before_create :assign_level

  validates_presence_of :value, message: 'Не введено варіант коду'

  validates_uniqueness_of :value, scope: [:question_id], message: 'Такий код вже є на рівні'

  scope :of_question, ->(question) { where(question_id: question.id) }

  protected

  def strip_spaces
    value.strip!
  end

  def assign_level
    self.level = question.level
  end
end
