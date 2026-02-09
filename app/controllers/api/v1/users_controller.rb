class Api::V1::UsersController < Api::V1::BaseController
  # GET /api/v1/users/current
  def current
    render json: {
      id: current_user.id,
      name: current_user.name,
      email: current_user.email,
      is_admin: current_user.is_ben?
    }
  end
end
