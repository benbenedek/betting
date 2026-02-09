require 'csv'
module ScoresHelper

  def get_score_table_csv(league_id)
    fixtures = Fixture.where(league_id: league_id).sort_by(&:number)

    CSV.generate(headers: true) do |csv|
      csv << ["match_id", "bet_id", "fixture_bet_id", "user", "fixture_number", "home_team", "away_team", "prediction", "actual_result", "bet_correctly"]
      User.all.each { |user|
        total_success = 0
        total_games = 0
        fixtures.each { |fixture|
          next unless fixture.has_any_scores?
          fb = fixture.get_fixture_bet
          user_fixture_bet = fb.get_fixture_bet_for_user(user, fixture.matches)
          success_count = 0
          user_fixture_bet.bets.each { |bet|
            next if bet.match.score.nil?
            next if fixture.id != bet.match.fixture_id
            csv << [bet.match.id, bet.id, fb.id, user.name, fixture.number, bet.match.home_info, bet.match.away_info, bet.prediction, bet.match.bet_score, bet.prediction.eql?(bet.match.bet_score)]
          }
        }
      }
    end
  end

  def get_score_table(league_id)
    results = { table_head: ["משתמש/מחזור"], res: {} }

    # Eager load all fixtures with matches in one query
    fixtures = Fixture.includes(:matches)
                      .where(league_id: league_id)
                      .order(:number)

    # Filter fixtures with scores (use in-memory check on already loaded matches)
    scored_fixtures = fixtures.select { |f| f.matches.any? { |m| m.score.present? } }
    fixture_ids = scored_fixtures.map(&:id)

    scored_fixtures.each { |fixture|
      results[:table_head].push("#{fixture.number}")
    }
    results[:table_head].push('סה"כ')

    # Early return if no scored fixtures
    return results if scored_fixtures.empty?

    # Load all users once
    users = User.all.to_a

    # Eager load ALL bets for all users for all relevant fixtures in ONE query
    # This replaces N*M queries with just 1
    # Include fixture_bet to avoid N+1 when accessing bet.user_bet.fixture_bet.fixture_id
    all_bets = Bet.joins(:user_bet => :fixture_bet)
                  .includes(:match, user_bet: [:user, :fixture_bet])
                  .where(fixture_bets: { fixture_id: fixture_ids })
                  .to_a

    # Build a lookup hash: { user_id => { fixture_id => [bets] } }
    bets_by_user_fixture = {}
    all_bets.each do |bet|
      user_id = bet.user_bet.user_id
      fixture_id = bet.user_bet.fixture_bet.fixture_id
      bets_by_user_fixture[user_id] ||= {}
      bets_by_user_fixture[user_id][fixture_id] ||= []
      bets_by_user_fixture[user_id][fixture_id] << bet
    end

    # Build matches lookup by fixture_id for bet_score calculation
    matches_by_fixture = {}
    scored_fixtures.each do |fixture|
      matches_by_fixture[fixture.id] = fixture.matches.index_by(&:id)
    end

    users.each do |user|
      results[:res][user.name] = {}
      total_success = 0
      total_games = 0

      scored_fixtures.each do |fixture|
        user_bets = bets_by_user_fixture.dig(user.id, fixture.id) || []
        matches_lookup = matches_by_fixture[fixture.id]

        success_count = 0
        games_count = 0

        user_bets.each do |bet|
          match = matches_lookup[bet.match_id]
          next if match.nil? || match.score.nil?

          games_count += 1
          success_count += 1 if bet.prediction == match.bet_score
        end

        results[:res][user.name][fixture.number.to_s] = {
          games: games_count,
          success: success_count
        }
        total_games += games_count
        total_success += success_count
      end

      results[:res][user.name][:total] = { games: total_games, success: total_success }
    end

    results[:res] = results[:res].sort_by { |k, v| v[:total][:success] }.reverse
    results
  end

  def prepare_graphs_data(data)
    hash = {}

    hash[:labels] = data[:table_head].map { |name|
      is_number?(name) ? "מחזור #{name.to_i}" : nil
    }.compact

    user_results = data[:res].to_h
    c = 160
    hash[:datasets] = user_results.map { |k,v|
      sum = 0
      user_data = v.map { |k2, v2|
        sum = v2[:success].to_i + sum
        sum
      }

      c = c + 20
      {
        label: k,
        fillColor: "rgba(#{c.to_i},#{c.to_i},220,0.2)",
        strokeColor: "rgba(220,220,220,1)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: user_data
      }
    }


    raw hash.to_json
  end
end
