class Level < ActiveRecord::Base
  belongs_to :game
  acts_as_list scope: :game
  
  has_many :questions, :dependent => :destroy
  has_many :answers
  has_many :hints, -> { order(:delay) }

  validates_presence_of :name, :message => "Не введено назву завдання"

  validates_presence_of :text, :message => "Не введено текст завдання"

  validates_presence_of :game

  validates_uniqueness_of :name, :scope => :game, :message => "Рівень з такою назвою уже є в даній грі"

  scope :of_game, ->(game) { where( :game_id => game.id ) }
  

  def next
    lower_item
  end

  def correct_answer=(answer)
    self.questions.build(:correct_answer => answer)
  end

  def correct_answer
    self.questions.empty? ? nil : self.questions.first.answers.first.value
  end

  def multi_question?
    self.questions.count > 1
  end

  def find_question_by_answer(answer_value)
    require "ee_strings.rb"
    self.questions.detect do |question|
      question.answers.any? {|answer| answer.value.to_s.upcase_utf8_cyr == answer_value.to_s.upcase_utf8_cyr }
    end
  end
end
