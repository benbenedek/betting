class ScoresController < ApplicationController
  include ScoresHelper

  def scoretablecsv
    redirect_to login_path and return unless logged_in?
    league_id = params[:league_id]
    @league = League.find(league_id)
    respond_to do |format|
      format.csv { send_data get_score_table_csv(league_id), filename: "league_#{params[:league_id]}.csv" }
    end
  end

  def scoretable
    redirect_to login_path and return unless logged_in?
    league_id = params[:league_id]
    @league = League.find(league_id)
    @results = get_score_table(league_id)
  end
end
