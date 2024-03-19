require_relative '../../lib/migration'

class BetsController < ApplicationController
  def index
    redirect_to login_path and return unless logged_in?
    # @fixture = params[:number].present? ?
    #   Fixture.where(league_id: params[:league_id].to_i, number: params[:number].to_i).includes(:matches, :fixture_bets).first :
    #   Fixture.get_upcoming_fixture

    @fixture = fetch_fixture_cached(params[:league_id], params[:number])

    return unless @fixture.present?

    if params[:nuke].present? && params[:nuke].to_s == '1' && current_user.is_ben?
      Rails.cache.clear
    end

    Rails.cache.fetch("hourly_migration_fixture_#{@fixture.id}", :expires_in => 6.hours) do
      if @fixture.can_still_bet_on_fixture?
        break
      end
      if @fixture.all_games_dont_hava_scores?
        begin
          Migration.fetch_fixture_one(@fixture.league_id, @fixture.number)
          @fixture.reload
        rescue => e
          Rails.logger.error "Got error #{e}\n#{e.backtrace}"
          break
        end
      end
      'OK'
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
    head 200, content_type: "text/html"
  end

  def open_close
    if current_user.is_ben?
      @fixture = Fixture.where(league_id: params[:league_id].to_i, number: params[:number].to_i).first
      return unless @fixture.present?

      @fixture.is_open = params[:should_open]
      @fixture.save!
      Rails.cache.clear
    end
    redirect_to index_path(league_id: params[:league_id].to_i, number: params[:number].to_i)
  end

  def fetch_fixture_cached(league_id, fixture_number)
    if fixture_number.present?
      Rails.cache.fetch("fixture_#{@league_id}_#{fixture_number}", :expires_in => 3.hours) do
        Fixture.where(league_id: league_id.to_i, number: fixture_number.to_i).includes({ :matches => [:away_team, :home_team]}).first
      end
    else
      Rails.cache.fetch("current_fixture", :expires_in => 3.hours) do
        res = Fixture.get_upcoming_fixture
        if res.nil?
          res = Fixture.get_previous_fixture
        end
        return res
      end
    end
  end

  def run_migration
    if current_user.is_ben?
      Migration.fetch_fixture_one(params[:league_id].to_i, params[:number].to_i)
      Rails.cache.clear
    end
    redirect_to index_path(league_id: params[:league_id].to_i, number: params[:number].to_i)
  end

end
