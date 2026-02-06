class ReactController < ApplicationController
  before_action :require_login

  def index
    @react_props = build_react_props
    render layout: 'react'
  end

  def bets
    @react_props = build_react_props.merge(
      league_id: params[:league_id],
      number: params[:number]
    )
    render :index, layout: 'react'
  end

  def scores
    @react_props = build_react_props.merge(
      league_id: params[:league_id]
    )
    render :index, layout: 'react'
  end

  private

  def build_react_props
    {
      current_user: current_user&.as_json(only: [:id, :name, :email]).merge(
        is_admin: current_user&.is_ben?
      ),
      csrf_token: form_authenticity_token
    }
  end

  def require_login
    unless logged_in?
      redirect_to login_path
    end
  end
end
