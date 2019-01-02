class ScoresController < ApplicationController
  include ScoresHelper

  def scoretable
    redirect_to login_path and return unless logged_in?
    league_id = params[:league_id]
    @league = League.find(league_id)
    @results = get_score_table(league_id)
  end
end
