class Api::V1::FixturesController < Api::V1::BaseController
  # GET /api/v1/fixtures/current
  def current
    @fixture = fetch_fixture_cached(nil, nil)
    render_fixture_response
  end

  # GET /api/v1/fixtures/:league_id/:number
  def show
    @fixture = fetch_fixture_cached(params[:league_id], params[:number])
    render_fixture_response
  end

  # GET /api/v1/fixtures/:id/all_bets
  def all_bets
    @fixture = Fixture.find(params[:id])

    if @fixture.can_still_bet_on_fixture?
      return render json: { error: 'Betting still open' }, status: :forbidden
    end

    # Get all users except current user (matches ERB behavior)
    other_users = User.where.not(id: current_user.id).order(:id)

    # Get fixture bets for each user
    user_bets_data = other_users.map do |user|
      user_fixture_bet = @fixture.get_fixture_bet_for_user(user)
      {
        user: {
          id: user.id,
          name: user.name
        },
        bets: user_fixture_bet&.bets&.map do |bet|
          {
            id: bet.id,
            match_id: bet.match_id,
            prediction: bet.prediction
          }
        end || []
      }
    end

    render json: {
      fixture_id: @fixture.id,
      user_bets: user_bets_data
    }
  end

  # POST /api/v1/fixtures/:id/toggle_open
  def toggle_open
    unless current_user.is_ben?
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    @fixture = Fixture.find(params[:id])
    @fixture.update!(is_open: params[:is_open] == 'true' || params[:is_open] == true)
    Rails.cache.clear

    render json: fixture_json(@fixture)
  end

  # POST /api/v1/fixtures/:league_id/:number/run_migration
  def run_migration
    unless current_user.is_ben?
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    require_relative '../../../../lib/migration'
    Migration.fetch_fixture_one(params[:league_id].to_i, params[:number].to_i)
    Rails.cache.clear

    render json: { success: true, message: 'Migration completed' }
  end

  private

  def render_fixture_response
    unless @fixture.present?
      return render json: { error: 'Fixture not found' }, status: :not_found
    end

    @user_fixture_bet = @fixture.get_fixture_bet_for_user(current_user)

    render json: {
      fixture: fixture_json(@fixture),
      matches: @fixture.matches.map { |m| match_json(m) },
      user_bets: user_bets_json(@user_fixture_bet),
      all_fixtures: Fixture.where(league_id: @fixture.league_id)
                           .order(:number)
                           .pluck(:id, :number, :league_id)
                           .map { |id, n, l| { id: id, number: n, league_id: l } },
      current_user: {
        id: current_user.id,
        name: current_user.name,
        is_admin: current_user.is_ben?
      }
    }
  end

  def fixture_json(fixture)
    {
      id: fixture.id,
      number: fixture.number,
      league_id: fixture.league_id,
      date: fixture.date,
      is_open: fixture.is_open,
      can_still_bet: fixture.can_still_bet_on_fixture?,
      seconds_left_to_bet: [fixture.seconds_left_to_bet, 0].max.to_i
    }
  end

  def match_json(match)
    {
      id: match.id,
      date: match.pretty_date,
      score: match.score,
      bet_score: match.has_score? ? match.bet_score : nil,
      can_still_bet: match.can_still_bet_on_match?,
      home_team: { id: match.home_team.id, name: match.home_team.name },
      away_team: { id: match.away_team.id, name: match.away_team.name }
    }
  end

  def user_bets_json(user_bet)
    return nil unless user_bet
    {
      id: user_bet.id,
      bets: user_bet.bets.map do |bet|
        {
          id: bet.id,
          match_id: bet.match_id,
          prediction: bet.prediction
        }
      end
    }
  end

  def fetch_fixture_cached(league_id, fixture_number)
    if fixture_number.present?
      Rails.cache.fetch("fixture_#{league_id}_#{fixture_number}", expires_in: 3.hours) do
        Fixture.where(league_id: league_id.to_i, number: fixture_number.to_i)
               .includes(matches: [:away_team, :home_team]).first
      end
    else
      Rails.cache.fetch("current_fixture", expires_in: 3.hours) do
        Fixture.get_upcoming_fixture || Fixture.get_previous_fixture
      end
    end
  end
end
