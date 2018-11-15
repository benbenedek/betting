module ApplicationHelper

  def is_number?(str)
    if !/\A\d+\z/.match(str)
        false
    else
        true
    end
  end

  # Logs in the given user.
  def log_in(user)
    session[:user_id] = user.id
  end

  # Returns the current logged-in user (if any).
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
  end

  def link_to_next_fixture(fixture)
    link_to "מחזור הבא", link_to_league_fixture(fixture.league_id, fixture.number + 1), :class=>"loader-ajax-link"
  end

  def link_to_prev_fixture(fixture)
    return if fixture.number < 2
    link_to "מחזור הקודם", link_to_league_fixture(fixture.league_id, fixture.number - 1), :class=>"loader-ajax-link"
  end

  def link_to_league_fixture(league_id, fixture_id)
    index_path(league_id: league_id, number: fixture_id)
  end

  def get_score_table(league_id)
    results = { table_head: ["משתמש/מחזור"], res: {} }
    fixtures = Fixture.where(league_id: league_id).sort_by(&:number)

    fixtures.each { |fixture|
      next unless fixture.has_any_scores?
      results[:table_head].push("#{fixture.number}")
    }
    results[:table_head].push('סה"כ')

    User.all.each { |user|
      results[:res][user.name] = {}
      total_success = 0
      total_games = 0
      fixtures.each { |fixture|
        next unless fixture.has_any_scores?
        fb = fixture.get_fixture_bet
        user_fixture_bet = fb.get_fixture_bet_for_user(user, fixture.matches)
        success_count = 0
        user_fixture_bet.bets.each { |bet| success_count += 1 if bet.prediction.eql?(bet.match.bet_score) }
        results[:res][user.name][fixture.number.to_s] = {}
        results[:res][user.name][fixture.number.to_s][:games] = user_fixture_bet.bets.count
        results[:res][user.name][fixture.number.to_s][:success] = success_count
        total_games += user_fixture_bet.bets.count
        total_success += success_count
      }

      results[:res][user.name][:total] = { games: total_games, success: total_success }
    }
    results[:res] = results[:res].sort_by { |k, v| v[:total][:success] }
    results[:res].reverse!
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
