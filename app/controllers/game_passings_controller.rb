class GamePassingsController < ApplicationController
  include GamePassingsHelper

  before_action :find_game, except: [:exit_game]
  before_action :find_game_by_id, only: [:exit_game]
  before_action :find_team, except: [:show_results, :index]
  before_action :find_or_create_game_passing, except: [:show_results, :index]
  before_action :authenticate_user!, except: [:index, :show_results]
  before_action :ensure_game_is_started
  before_action :ensure_team_captain, only: [:exit_game]
  before_action :ensure_not_finished, except: [:index, :show_results]
  before_action :author_finished_at, except: [:index, :show_results]
  before_action :ensure_team_member, except: [:index, :show_results]
  before_action :ensure_not_author_of_the_game, except: [:index, :show_results]
  before_action :ensure_author, only: [:index]
  #before_action :get_uniq_level_codes, only: [:show_current_level]
  #before_action :get_answered_questions, only: [:show_current_level]

  def show_current_level
    if @game_passing.finished_at.nil?
      @level = if @game.game_type == 'panic'
               params[:level] ? @game.levels.where(position: params[:level]).first : @game.levels.first
              else
                @game_passing.current_level
              end
      get_uniq_level_codes(@level)
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
    next_hint = @game_passing.upcoming_hints.first

    render json: { hint_num: @game_passing.hints_to_show.length,
                   hint_text: @game_passing.hints_to_show.last.text.html_safe,
                   next_available_in: next_hint.nil? ? nil : next_hint.available_in(@game_passing.current_level_entered_at) }.to_json
  end

  def post_answer
    if @game_passing.finished? ||
       @game.game_type == 'panic' &&
       @game.starts_at + 60 * @game.duration < Time.zone.now
      render 'show_results'
    else
      @answer = params[:answer].strip
      @level = @game.game_type == 'panic' ? @game.levels.find(params[:level_id]) : @game_passing.current_level
      save_log(@level) if @game_passing.current_level.id || @game.game_type == 'panic'
      @answer_was_correct = @game_passing.check_answer!(@answer, @level)
      if @game_passing.finished?
        render 'show_results'
      else
        get_uniq_level_codes(@level)
        get_answered_questions(@level) unless @game.game_type == 'panic'
        render 'show_current_level', layout: 'in_game'
      end
    end
  end

  def save_log(level = @game_passing.current_level)
    Log.create! game_id: @game.id,
                level: level.name,
                team: @team.name,
                time: Time.zone.now,
                answer: @answer ? @answer : 'timeout',
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
    if @game_passing.finished?
      render json: { result: true }.to_json
    else
      @game_passing.autocomplete_level!(@game_passing.current_level)
      save_log(@game_passing.current_level)
      if @game_passing.finished?
        render json: { result: true }.to_json
      else
        render json: { result: true }.to_json
      end
    end
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
                                          current_level: @game.levels.first
    end
  end

  def find_team
    @team = current_user.team
  end

  def ensure_game_is_started
    redirect_to game_path(@game), alert: 'Заборонено грати в гру до її початку' unless @game.is_testing? || @game.started?
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
    log_of_level = Log.of_game(@game).of_level(level).of_team(current_user.team)
    entered_answers = log_of_level.map(&:answer).uniq
    @entered_all_answers = entered_answers
    level.questions.each do |question|
      question.answers.each do |answer|
        correct_answers << answer.value
      end
    end
    @entered_correct_answers = entered_answers & correct_answers
  end

  def get_answered_questions(level)
    @sectors = []
    return unless level.multi_question?
    answered_questions = @game_passing.answered_questions
    @game_passing.current_level.questions.each do |question|
      value = level.olymp? ? question.name : '-'
      @sectors << { position: question.position,
                    name: question.name,
                    value: answered_questions.include?(question) ? "<b><font color=\"236400\">#{question.correct_answer}</font></b>" : value }
    end
  end
end
