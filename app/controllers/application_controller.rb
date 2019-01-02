require 'migration'

class ApplicationController < ActionController::Base
  include ApplicationHelper

  protect_from_forgery :except => :fixture

  before_action :check_logged_in

  def check_logged_in
    return if logged_in?
    return unless cookies.signed[:user_id].present? && cookies.signed[:auth_token].present?

    user = User.where(id: cookies.signed[:user_id], auth_token: cookies.signed[:auth_token]).first
    log_in(user) if user.present?
  end

end
