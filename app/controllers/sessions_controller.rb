class SessionsController < ApplicationController
  include ApplicationHelper

  def new
  end

  def create
    user = User.find_by(email: params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      # Log the user in and redirect to the user's show page.
      if params[:session][:remember_me] == '1'
        user.generate_token!
        cookies.permanent.signed[:auth_token] = user.auth_token
        cookies.permanent.signed[:user_id] = user.id
      end
      log_in user
      redirect_to root_path
    else
      # Create an error message.
      flash[:danger] = 'משתמש וסיסמא לא נכונים' # Not quite right!
      render 'new'
    end
  end

  def destroy
    current_user.auth_token = nil
    current_user.save(validate: false)
    log_out
    redirect_to login_path
  end

end
