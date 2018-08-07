class LevelsController < ApplicationController
  before_action :find_game
  before_action :ensure_game_was_not_finished, except: [:show, :dismiss, :undismiss]
  before_action :ensure_author
  before_action :find_level, except: [:new, :create]

  def new
    @level = @game.levels.build
    # @level.questions.build
    # @level.questions.first.answers.build
  end

  def create
    @level = @game.levels.build(level_params)
    if @level.save
      redirect_to game_level_path(@game, @level)
    else
      render 'new'
    end
  end

  def show
    render
  end

  def edit
    render
  end

  def update
    if @level.update_attributes(level_params)
      redirect_to game_level_path(@level.game, @level)
    else
      render 'edit'
    end
  end

  def destroy
    @level.destroy
    redirect_to game_path(@game)
  end

  def move_up
    @level.move_higher
    redirect_to game_path(@game, anchor: "level-#{@level.position}")
  end

  def move_down
    @level.move_lower
    redirect_to game_path(@game, anchor: "level-#{@level.position}")
  end

  def change_position
    @level.insert_at(params[:position])
    redirect_to game_path(@game, anchor: "level-#{@level.position}")
  end

  def copy
    @new_level = @level.dup
    @new_level.set_list_position(@game.levels.count + 1)
    @level.tasks.each do |task|
      new_task = task.dup
      new_task.level_id = nil
      @new_level.tasks << new_task
    end
    @level.hints.each do |hint|
      new_hint = hint.dup
      new_hint.level_id = nil
      @new_level.hints << new_hint
    end
    @level.penalty_hints.each do |hint|
      new_hint = hint.dup
      new_hint.level_id = nil
      @new_level.penalty_hints << new_hint
    end
    @level.questions.each do |question|
      new_question = question.dup
      new_question.level_id = nil
      question.answers.each do |answer|
        new_answer = answer.dup
        new_answer.question_id = nil
        new_question.answers << new_answer
      end
      @new_level.questions << new_question
    end
    @level.bonuses.each do |bonus|
      @new_level.bonuses << bonus
    end
    if @new_level.save
      redirect_to game_path(@game)
    else
      p @new_level.errors
      flash[:notice] = 'ERROR: Item can\'t be cloned.'
      redirect_to game_path(@game)
    end
  end

  def dismiss
    @level.dismiss!(current_user.id)
    redirect_to game_path(@game)
  end

  def undismiss
    @level.undismiss!
    redirect_to game_path(@game)
  end

  def add_answer_to_sectors
    answer_value = params[:answer]
    unless answer_value.strip.empty?
      @level.questions.each do |question|
        unless question.answers.pluck(:value).include?(answer_value)
          question.answers.build(value: answer_value)
          question.save!
        end
      end
    end
    redirect_to game_level_path(@level.game, @level)
  end

  def add_answer_to_bonuses
    answer_value = params[:bonus_answer]
    unless answer_value.strip.empty?
      @level.bonuses.each do |bonus|
        unless bonus.bonus_answers.pluck(:value).include?(answer_value)
          bonus.bonus_answers.build(value: answer_value)
          bonus.save!
        end
      end
    end
    redirect_to game_level_path(@level.game, @level)
  end

  protected

  def level_params
    # params.require(:level).permit(:name, :text, :correct_answer, :olymp, :complete_later_minutes)
    params.require(:level).permit(
        :name, :olymp, :complete_later, :olymp_base, :sectors_for_close, :description,
        :is_autocomplete_penalty, :autocomplete_penalty, :is_wrong_code_penalty, :wrong_code_penalty
    )
  end

  def find_game
    @game = Game.friendly.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:id])
  end
end
