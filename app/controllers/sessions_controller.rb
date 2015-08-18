class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      sign_in user
      redirect_to dashboard_path
    else
      flash.now[:error] = 'Невірна комбінація email/пароль'
      render 'new'
    end
  end

  def destroy
    sign_out
    flash.now[:error] = 'signout'
    redirect_to root_url
  end
end
