class UsersController < ApplicationController
  before_filter :find_user, only: [:show, :edit, :update, :destroy]
  before_action :signed_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]

  def show
    render text: 'Сторінку не знайдено', status: 404 unless @user
  end

  def index
    render
  end

  def new
    @user = User.new
  end

  def create
    @user = User.create(user_create_params)
    if @user.save
      sign_in @user
      redirect_to dashboard_path
    else
      render 'new'
    end
  end

  def edit
    # render
  end

  def update
    @user.update(user_edit_params)
    if @user.errors.empty?
      redirect_to dashboard_path
    else
      render 'edit'
    end
  end

  def destroy
    redirect_to users_path
  end

  private

  def user_create_params
    params.require(:user).permit(:nickname, :email, :password)
  end

  def user_edit_params
    params.require(:user).permit(:nickname, :email, :icq_number,
                                 :jabber_id, :date_of_birth,
                                 :phone_number, :password)
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  def authenticate_user
    session.user = @user
  end

  def find_user
    @user = User.find(params[:id])
  end
end
