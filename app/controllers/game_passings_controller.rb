class GamePassingsController < ApplicationController
  include GamePassingsHelper

  before_action :authenticate_user!, except: [:index, :show_results]
  before_action :find_game, except: [:exit_game]
  before_action :find_game_by_id, only: [:exit_game]
  before_action :ensure_user_has_team, only: [:show_current_level, :get_current_level_tip, :post_answer, :autocomplete_level]
  before_action :find_team, except: [:show_results, :index]
  before_action :find_team_id, only: [:show_current_level, :get_current_level_tip, :post_answer, :autocomplete_level]
  before_action :ensure_game_is_started
  before_action :ensure_not_author_of_the_game, except: [:index, :show_results]
  before_action :find_or_create_game_passing, except: [:show_results, :index]
  before_action :ensure_team_captain, only: [:exit_game]
  before_action :ensure_not_finished, except: [:index, :show_results]
  before_action :author_finished_at, except: [:index, :show_results]
  before_action :ensure_team_member, except: [:index, :show_results]
  before_action :ensure_author, only: [:index]
  # before_action :get_uniq_level_codes, only: [:show_current_level]
  # before_action :get_answered_questions, only: [:show_current_level]

  def show_current_level
    if @game_passing.finished_at.nil?
      @level = if @game.game_type == 'panic'
                 params[:level] ? @game.levels.where(position: params[:level]).first : @game.levels.first
               else
                 @game_passing.current_level
               end
      get_uniq_level_codes(@level)
      get_answered_bonuses(@level) unless @game.game_type == 'panic'
      get_answered_questions(@level) unless @game.game_type == 'panic'
      render layout: 'in_game'
    else
      render 'show_results'
    end
  end

  def index
    @game_passings = GamePassing.of_game(@game)
    render
  end

  def get_current_level_tip
    next_hint = @game_passing.upcoming_hints(@team_id).first
    hints_to_show = @game_passing.hints_to_show(@team_id)

    render json: { hint_num: hints_to_show.length,
                   hint_text: hints_to_show.last.text.html_safe,
                   hint_count: @game_passing.hints_to_show(@team_id).count + @game_passing.upcoming_hints(@team_id).count,
                   next_available_in: next_hint.nil? ? nil : next_hint.available_in(@game_passing.current_level_entered_at) }.to_json
  end

  def post_answer
    time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time
    if @game_passing.finished? ||
       @game.game_type == 'panic' &&
       @game.starts_at + 60 * @game.duration < time
      render 'show_results'
    else
      @answer = params[:answer].strip
      if @answer == ''
        @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
        get_uniq_level_codes(@level)
        get_answered_bonuses(@level) unless @game.game_type == 'panic'
        get_answered_questions(@level) unless @game.game_type == 'panic'
        render 'show_current_level', layout: 'in_game'
      else
        @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
        save_log(@level, time) if @game_passing.current_level.id || @game.game_type == 'panic'
        @answer_was_correct = @game_passing.check_answer!(@answer, @level, @team_id, time)
        if @game_passing.finished?
          PrivatePub.publish_to "/game_passings/#{@game_passing.id}", url: '/game_passings/show_results'
          render 'show_results'
        else
          @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
          get_uniq_level_codes(@level)
          get_answered_bonuses(@level) unless @game.game_type == 'panic'
          get_answered_questions(@level) unless @game.game_type == 'panic'
          render 'show_current_level', layout: 'in_game'
        end
      end
    end
  end

  def save_log(level = @game_passing.current_level, time = Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time)
    Log.create! game_id: @game.id,
                level: level.name,
                level_id: level.id,
                team: @team.name,
                team_id: @team.id,
                time: time,
                answer: @answer || 'timeout',
                user: current_user
  end

  def show_results
    render
  end

  def exit_game
    @game_passing.exit!
    render 'show_results'
  end

  def autocomplete_level
    level_id = params[:level]
    unless @game_passing.finished?
      level = Level.find(level_id)
      @game_passing = GamePassing.of(@team, @game)
      if level == @game_passing.current_level
        begin
          save_log(level, (level.position == 1 ? @game.starts_at : @game_passing.current_level_entered_at) + level.complete_later)
          @game_passing.autocomplete_level!(level, @team_id)
        rescue

        end
      end
    end
    render json: { result: true }.to_json
  end

  protected

  def find_game
    @game = Game.find(params[:game_id])
  end

  def find_game_by_id
    @game = Game.find(params[:id])
  end

  # TODO: must be a critical section, double creation is possible!
  def find_or_create_game_passing
    @game_passing = GamePassing.of(@team, @game)

    if @game_passing.nil?
      @game_passing = GamePassing.create! team: @team,
                                          game: @game,
                                          current_level: @game.game_type == 'selected' ? Level.find_by_id(LevelOrder.of(@game, Team.find_by_id(@team_id)).first.level_id) : @game.levels.first
    end
  end

  def find_team
    @team = current_user.team
    if @game.is_testing? && !@game.tested_team_id.nil?
      @team = Team.find(@game.tested_team_id)
    end
  end

  def find_team_id
    @team_id = current_user.team.id
    if @game.is_testing? && !@game.tested_team_id.nil?
      @team_id = @game.tested_team_id
    end
  end

  def ensure_game_is_started
    unless (@game.is_testing? ? @game.test_date : @game.starts_at) < Time.zone.now.strftime("%d.%m.%Y %H:%M:%S.%L").to_time ||
        @game.is_testing? && current_user.author_of?(@game)
      redirect_to game_path(@game), alert: 'Заборонено грати в гру до її початку'
    end
  end

  def ensure_user_has_team
    if current_user.team.nil?
      redirect_to game_path(@game), alert: 'Необхідно створити команду або зайти в уже створену'
    end
  end

  def ensure_not_author_of_the_game
    redirect_to game_path(@game), alert: 'Заборонено грати власні ігри' unless @game.is_testing? || !@game.created_by?(current_user)
  end

  def author_finished_at
    redirect_to game_path(@game), alert: 'Гру завершено автором, і ви не можете її більше грати' if @game.author_finished?
  end

  def ensure_captain_exited
    redirect_to game_path(@game), alert: 'Команда зійшла з дистанції' if @game_passing.exited?
  end

  def ensure_not_finished
    author_finished_at
    ensure_captain_exited
  end

  def get_uniq_level_codes(level)
    correct_answers = []
    log_of_level = Log.of_game(@game).of_level(level).of_team(Team.find(@team_id))
    entered_answers = log_of_level.map(&:answer).uniq || []
    @entered_all_answers = entered_answers
    level.team_questions(@team_id).includes(:answers).each do |question|
      question.answers.select{ |answer| answer.team_id.nil? || answer.team_id == @team_id }.each do |answer|
        correct_answers << answer.value
      end
    end
    level.team_bonuses(@team_id).includes(:bonus_answers).each do |bonus|
      bonus.bonus_answers.select{ |answer| answer.team_id.nil? || answer.team_id == @team_id }.each do |answer|
        correct_answers << answer.value
      end
    end
    @entered_correct_answers = entered_answers & correct_answers
  end

  def get_answered_questions(level)
    @sectors = []
    return unless level.multi_question?(@team_id)
    answered_questions = @game_passing.current_level.questions.where(id: @game_passing.answered_questions)
    @game_passing.current_level.team_questions(@team_id).includes(:answers).each do |question|
      correct_answers = question.answers.select { |ans| ans.team_id.nil? || ans.team_id == @team_id }
      value = level.olymp? ? question.name : '-'
      @sectors << { position: question.position,
                    name: question.name,
                    value: answered_questions.include?(question) ? "<span class=\"right_code\">#{correct_answers.count == 0 ? nil : correct_answers[0].value}</span>" : value }
    end
  end

  def get_answered_bonuses(level)
    @bonuses = []
    return unless level.has_bonuses?(@team_id)
    answered_bonuses = @game_passing.current_level.bonuses.where(id: @game_passing.answered_bonuses)
    @bonuses = @game_passing.current_level.team_bonuses(@team_id).includes(:bonus_answers).map do |bonus|
      correct_answers = bonus.bonus_answers.select { |ans| ans.team_id.nil? || ans.team_id == @team_id }
      {
        position: bonus.position,
        name: bonus.name,
        answered: answered_bonuses.include?(bonus),
        value: answered_bonuses.include?(bonus) ? "<span class=\"right_code\">#{correct_answers.count == 0 ? nil : correct_answers[0].value}</span>" : nil,
        task: bonus.task,
        help: answered_bonuses.include?(bonus) ? bonus.help : nil,
        award: answered_bonuses.include?(bonus) ? (bonus.award_time || 0) : nil
      }
    end
    @bonuses
  end
end
