class BetsController < ApplicationController
  def index
    redirect_to login_path and return unless logged_in?
    # @fixture = params[:number].present? ?
    #   Fixture.where(league_id: params[:league_id].to_i, number: params[:number].to_i).includes(:matches, :fixture_bets).first :
    #   Fixture.get_upcoming_fixture

    @fixture = fetch_fixture_cached(params[:league_id], params[:number])

    return unless @fixture.present?

    Rails.cache.fetch("hourly_migration_fixture_#{@fixture.id}", :expires_in => 3.hours) do
      if @fixture.can_still_bet_on_fixture?
        break
      end
      if @fixture.all_games_dont_hava_scores?
        begin
          Migration.delay.fetch_fixture(@fixture.league_id, @fixture.number)
          @fixture.reload
        rescue => e
          Rails.logger.error "Got error #{e}\n#{e.backtrace}"
          break
        end
      end
      'OK'
    end
    @previous_matches = Rails.cache.fetch("previous_matches_scores_#{@fixture.id}", :expires_in => 24.hours) do
      @fixture.get_previous_scores
    end
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

  def open_close
    @fixture = Fixture.where(league_id: params[:league_id].to_i, number: params[:number].to_i).first
    return unless @fixture.present?

    @fixture.is_open = params[:should_open]
    @fixture.save!
    redirect_to root_path
  end

  def fetch_fixture_cached(league_id, fixture_number)
    if fixture_number.present?
      # Rails.cache.fetch("fixture_#{@league_id}_#{fixture_number}", :expires_in => 3.hours) do
        Fixture.where(league_id: league_id.to_i, number: fixture_number.to_i).includes({ :matches => [:away_team, :home_team]}).first
      # end
    else
      # Rails.cache.fetch("current_fixture", :expires_in => 3.hours) do
        Fixture.get_upcoming_fixture
      # end
    end
  end
end
