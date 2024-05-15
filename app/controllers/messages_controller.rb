class MessagesController < ApplicationController
  before_action :find_game
  before_action :ensure_game_was_not_finished, except: [:show]
  before_action :ensure_author
  before_action :find_level
  before_action :find_message, only: [:edit, :update, :destroy]

  def index

  end

  def new
    @message = @game.messages.build
  end

  def create
    params[:message][:level_ids] ||= [@level.id]
    @message = @game.messages.build(message_params)
    @message.user = current_user
    if @message.save
      redirect_to game_level_path(@game, @level, anchor: 'messages_block')
    else
      render :new
    end
  end

  def show
    redirect_to game_level_path(@game, @level)
  end

  def edit

  end

  def update
    params[:message][:level_ids] ||= [@level.id]
    if @message.update(message_params)
      redirect_to game_level_path(@game, @level, anchor: 'messages-block')
    else
      render :edit
    end
  end

  def destroy
    @message.destroy
    redirect_to game_level_path(@game, @level, anchor: 'messages-block')
  end

  protected

  def message_params
    params.require(:message).permit(
        :text, :game_id, :user_id, level_ids: []
    )
  end

  def find_game
    @game = Game.friendly.find(params[:game_id])
  end

  def find_level
    @level = Level.find(params[:level_id])
  end

  def find_message
    @message = Message.find(params[:id])
  end

end