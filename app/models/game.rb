class Game < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  MAX_TEAMS_COUNT = 10_000

  belongs_to :author, class_name: 'User'
  has_and_belongs_to_many :authors, class_name: 'User', join_table: 'games_authors', foreign_key: 'game_id', association_foreign_key: 'author_id'
  has_many :levels, -> { order(:position) }
  has_many :level_orders
  has_many :logs, -> { order(:time) }
  has_many :game_entries, class_name: 'GameEntry'
  has_many :game_passings, class_name: 'GamePassing'
  has_many :game_bonuses, class_name: 'GameBonus', dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :bonuses, -> { order(:position) }, dependent: :destroy

  delegate :nickname, :telegram, to: :author, prefix: true

  validates_presence_of :name,
                        message: 'Не введено назву гри'

  validates_presence_of :starts_at,
                        message: 'Не введено дату старту гри'

  validates_uniqueness_of :name,
                          message: 'Гра з такою назвою уже існує'

  validates_presence_of :description,
                        message: 'Не введено опис гри'

  validates_numericality_of :max_team_number,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: MAX_TEAMS_COUNT, allow_nil: true,
                            message: 'Не коректно вказано обмеження на кількість команд у грі'

  validates_presence_of :author

  #validate :game_starts_in_the_future
  validate :valid_max_num

  # validate :deadline_is_in_future
  # validate :deadline_is_before_game_start

  before_save do
    if !draft? && topic_id.nil?
      topic_name = "#{name} (#{starts_at.strftime('%H:%M %d.%m.%Y')})"
      topic = Forem::Forum.where(name: "#{game_size || 'Лайт'}и").first.topics.build(subject: topic_name, user: author, posts_attributes: [text: topic_name])
      topic.save!
      self.topic_id = topic.id
    end
  end

  scope :by, -> (author_id) { where(author_id: author_id) }
  scope :non_drafts, -> { where(is_draft: false) }
  scope :finished, -> { where('author_finished_at IS NOT NULL') }
  scope :not_finished, -> { where('author_finished_at IS NULL') }

  def slug_candidates
    [
      [:transliterated_name, :id]
    ]
  end

  def transliterated_name
    I18n.transliterate(self.name.mb_chars.downcase.to_s)
  end

  def self.started
    Game.order(starts_at: :desc).all.select(&:started?)
  end

  def draft?
    self.is_draft
  end

  def started?
    (self.starts_at.nil? ? false : Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time) > (self.is_testing? ? self.test_date : self.starts_at)
  end

  def created_by?(user)
    user.author_of?(self)
  end

  def finished_teams
    GamePassing.of_game(id).finished.map(&:team)
  end

  def place_of(team)
    game_passing = GamePassing.of(team.id, id)
    return nil unless game_passing && (game_passing.finished? || self.game_type == 'panic')
    if self.game_type == 'linear' || game_passing.finished_at
      count_of_finished_before =
        GamePassing.of_game(id).finished_before(game_passing.finished_at).size
    else
      count_of_finished = GamePassing.finished.size
      count_of_finished_before = count_of_finished +
        GamePassing.of_game(id).select do |game_pass|
          !game_passing.finished_at &&
          game_pass.closed_levels.size > game_passing.closed_levels.size ||
          game_pass.closed_levels.size == game_passing.closed_levels.size &&
          game_pass.current_level_entered_at < game_passing.current_level_entered_at
        end.size
    end
    count_of_finished_before + 1
  end

  def self.notstarted
    Game.all.order(starts_at: :asc).select { |game| !game.draft? && !game.started? }
  end

  def free_place_of_team!
    if self.requested_teams_number > 0
      self.requested_teams_number -= 1
      save
    end
  end

  def reserve_place_for_team!
    self.requested_teams_number += 1
    save
  end

  def can_request?
    self.max_team_number.nil? || self.requested_teams_number < self.max_team_number
    Game.all.select { |game| !game.started? }
  end

  def finish_game!
    self.create_results
    self.author_finished_at = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    self.save!
  end

  def open_game!
    self.author_finished_at = nil
    self.save!
  end

  def author_finished?
    !self.author_finished_at.nil?
  end

  def is_testing?
    self.is_testing
  end

  def start_test!(team_id)
    self.is_testing = 't'
    self.test_date = self.starts_at
    self.starts_at = Time.zone.now + 0.1.second
    self.registration_deadline = nil
    self.tested_team_id = team_id
    self.save!
  end

  def stop_test!
    self.is_testing = 'f'
    self.starts_at = self.test_date
    self.test_date = Time.zone.now
    self.tested_team_id = nil
    self.save!

    game_passing = GamePassing.of_game(id)
    logs = Log.of_game(id)
    input_locks = InputLock.of_game(id)
    game_bonuses = GameBonus.of_game(id)
    closed_levels = ClosedLevel.of_game(id)
    game_passing.each do |elem|
      elem.questions.clear
      elem.bonuses.clear
    end

    game_passing.delete_all
    logs.delete_all
    input_locks.delete_all
    game_bonuses.delete_all
    closed_levels.delete_all
  end

  def create_results
    game_bonuses = GameBonus.of_game(id).select("team_id, sum(award) as sum_bonuses").group(:team_id).to_a
    game_passings = GamePassing.of_game(id).includes(:team)
    if game_type == 'panic'
      game_finished_at = starts_at + duration * 60
      game_results = game_passings.map do |game_passing|
        team_bonus = game_bonuses.select{ |bonus| bonus.team_id == game_passing.team_id}
        {
            team_id: game_passing.team_id,
            team_name: game_passing.team_name,
            finished_at: game_passing.finished_at || game_finished_at,
            closed_levels: game_passing.closed_levels.size,
            sum_bonuses: (game_passing.sum_bonuses || 0) + (team_bonus.empty? ? 0 : team_bonus[0].sum_bonuses)
        }
      end.sort do |a, b|
        (a[:finished_at] - a[:sum_bonuses]) <=> (b[:finished_at] - b[:sum_bonuses])
      end
    else
      current_time = Time.now
      game_results = game_passings.map do |game_passing|
        team_bonus = game_bonuses.select{ |bonus| bonus.team_id == game_passing.team_id}
        {
            team_id: game_passing.team_id,
            team_name: game_passing.team_name,
            finished_at: game_passing.finished_at,
            closed_levels: game_passing.closed_levels.size,
            sum_bonuses: (game_passing.sum_bonuses || 0) + (team_bonus.empty? ? 0 : team_bonus[0].sum_bonuses),
            exited: game_passing.exited?
        }
      end.sort_by do |v|
        [-v[:closed_levels], (v[:finished_at] || current_time) - v[:sum_bonuses]]
      end
    end
    Result.delete_all(game_id: id)
    game_results.each_with_index do |result, index|
      Result.create!(game_id: id, team_id: result[:team_id], place: result[:finished_at].nil? && !game_type == 'panic' ? -1 : (index + 1))
    end
  end

  protected

  def game_starts_in_the_future
    if self.author_finished_at.nil? && self.starts_at && self.starts_at < Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
      errors.add(:starts_at, 'Вибрано дату із минулого.')
    end
  end

  def valid_max_num
    if self.max_team_number
      if self.max_team_number < self.requested_teams_number
        errors.add(:max_team_number, 'Кількість команд, що подали заявку, перевищує дозволене число')
      end
    end
  end

  def deadline_is_in_future
    if self.author_finished_at.nil? && self.registration_deadline &&
        self.registration_deadline < Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
      errors.add(:registration_deadline, 'Вказано кінцевий термін реєстрації із минулого')
    end
  end

  def deadline_is_before_game_start
    if self.registration_deadline &&
       self.starts_at && self.registration_deadline > self.starts_at
      errors.add(:registration_deadline, 'Вказано кінцевий термін реєстрації пізніший дати початку гри')
    end
  end


end
