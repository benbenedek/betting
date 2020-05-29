class BetsController < ApplicationController
  def index
    redirect_to login_path and return unless logged_in?
    @fixture = params[:number].present? ?
      Fixture.where(league_id: params[:league_id].to_i, number: params[:number].to_i).includes(:matches).first :
      Fixture.get_upcoming_fixture

    return unless @fixture.present?

    Rails.cache.fetch("hourly_migration_fixture_#{@fixture.id}", :expires_in => 1.hours) do
      return nil if @fixture.can_still_bet_on_fixture?
      if @fixture.all_games_dont_hava_scores?
        begin
          Migration.fetch_fixture(@fixture.league_id, @fixture.number)
          @fixture.reload
        rescue => e
          Rails.logger.error "Got error #{e}\n#{e.backtrace}"
          break
        end
      end
    end
    @previous_matches = @fixture.get_previous_scores
    @user_fixture_bet = @fixture.get_fixture_bet_for_user(current_user)
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
