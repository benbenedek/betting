class Api::V1::BaseController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate_api_request

  private

  def authenticate_api_request
    unless logged_in?
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
