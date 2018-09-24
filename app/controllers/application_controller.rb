require 'migration'

class ApplicationController < ActionController::Base
  include ApplicationHelper

  protect_from_forgery :except => :fixture

  def index
    redirect_to login_path and return unless logged_in?
    @fixture = params[:number].present? ?
      Fixture.where(league_id: params[:league_id].to_i, id: params[:number].to_i).first :
      Fixture.get_upcoming_fixture

    return unless @fixture.present?

    Rails.cache.fetch("hourly_migration_fixture_#{@fixture.id}", :expires_in => 1.hours) do
      if @fixture.all_games_dont_hava_scores?
        Migration.get_scores_for_fixture_id(@fixture.league_id, @fixture.id)
        @fixture.reload
      end
    end

    @user_fixture_bet = @fixture.get_fixture_bet_for_user(current_user)
  end

  def scoretable
    redirect_to login_path and return unless logged_in?
    @results = get_score_table
  end

  def place_bet
    bet_id = params[:match_bet_id]
    prediction = params[:prediction]
    render status: 400, nothing: true && return if bet_id.nil? || prediction.nil?
    render status: 400, nothing: true && return unless ["1", "2", "X"].include?(prediction)

    bet = Bet.find(bet_id.to_i)
    render status: 400, nothing: true && return if bet.nil?

    render status: 400, nothing: true && return unless bet.user_bet.user.id == current_user.id

    bet.prediction = prediction
    bet.save
    render status: 200, nothing: true
  end

end
