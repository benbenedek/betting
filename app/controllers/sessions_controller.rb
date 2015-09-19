class SessionsController < ApplicationController
  include ApplicationHelper

  def new
  end

  def create
    user = User.find_by(email: params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      # Log the user in and redirect to the user's show page.
      log_in user
      redirect_to user
    else
      # Create an error message.
      flash[:danger] = 'Invalid name/password combination' # Not quite right!
      render 'new'
    end
  end

  def destroy
    log_out
    redirect_to login_path
  end

end
