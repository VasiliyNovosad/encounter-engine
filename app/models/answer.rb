class Answer < ActiveRecord::Base
  belongs_to :question
  belongs_to :level
  belongs_to :team

  before_save :strip_spaces

  validates_presence_of :value, message: 'Не введено варіант коду'

  validates_uniqueness_of :value, scope: [:question_id], message: 'Такий код вже є на рівні'

  scope :of_question, ->(question) { where(question_id: question.id) }

  protected

  def strip_spaces
    value.strip!
  end

end
