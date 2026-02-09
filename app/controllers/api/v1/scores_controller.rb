class Api::V1::ScoresController < Api::V1::BaseController
  include ScoresHelper

  # GET /api/v1/scores/:league_id
  def show
    league_id = params[:league_id] || 10
    @league = League.find_by(id: league_id)

    unless @league
      return render json: { error: 'League not found' }, status: :not_found
    end

    # Cache the results for 5 minutes - invalidated when scores change
    cache_key = "api_scores_#{league_id}_v2"
    cached_response = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      results = get_score_table(league_id)
      all_leagues = League.all.map { |l| { id: l.id, name: l.pretty_name } }

      {
        league: {
          id: @league.id,
          name: @league.pretty_name
        },
        all_leagues: all_leagues,
        table_head: results[:table_head],
        scores: format_scores(results[:res]),
        graph_data: format_graph_data(results)
      }
    end

    render json: cached_response
  end

  private

  def format_scores(res)
    res.map.with_index do |(user_name, fixtures), index|
      # Calculate stats
      fixture_list = fixtures.reject { |k, _| k == :total }
      total_data = fixtures[:total] || { games: 0, success: 0 }
      
      total_games = total_data[:games].to_i
      total_success = total_data[:success].to_i
      accuracy = total_games > 0 ? (total_success.to_f / total_games * 100).round(1) : 0
      
      # Find best fixture
      best_fixture = fixture_list.max_by { |_, data| data[:success].to_i }
      best_fixture_info = best_fixture ? { 
        number: best_fixture[0].to_s, 
        success: best_fixture[1][:success] 
      } : nil
      
      # Form guide (last 5 fixtures)
      recent_fixtures = fixture_list.to_a.last(5)
      form_guide = recent_fixtures.map do |fixture_key, data|
        games = data[:games].to_i
        success = data[:success].to_i
        # Consider good if got more than half right
        games > 0 && success >= (games / 2.0).ceil ? 'W' : 'L'
      end
      
      {
        user: user_name,
        rank: index + 1,
        total_games: total_games,
        total_success: total_success,
        accuracy: accuracy,
        best_fixture: best_fixture_info,
        form_guide: form_guide,
        fixtures: fixtures.map do |fixture_key, data|
          {
            fixture: fixture_key.to_s,
            games: data[:games],
            success: data[:success]
          }
        end
      }
    end
  end

  def format_graph_data(data)
    labels = data[:table_head].select { |name| is_number?(name) }.map { |name| "מחזור #{name.to_i}" }

    user_results = data[:res].to_h
    datasets = user_results.map.with_index do |(user_name, fixtures), index|
      sum = 0
      cumulative_data = fixtures.map do |fixture_key, data|
        sum += data[:success].to_i
        sum
      end

      {
        label: user_name,
        data: cumulative_data,
        borderColor: chart_color(index),
        backgroundColor: chart_color(index, 0.2),
        fill: false,
        tension: 0.4
      }
    end

    {
      labels: labels,
      datasets: datasets
    }
  end

  def chart_color(index, alpha = 1)
    colors = [
      "rgba(54, 162, 235, #{alpha})",   # blue
      "rgba(255, 99, 132, #{alpha})",   # red
      "rgba(75, 192, 192, #{alpha})",   # teal
      "rgba(255, 206, 86, #{alpha})",   # yellow
      "rgba(153, 102, 255, #{alpha})",  # purple
      "rgba(255, 159, 64, #{alpha})",   # orange
      "rgba(199, 199, 199, #{alpha})",  # grey
      "rgba(83, 102, 255, #{alpha})",   # indigo
    ]
    colors[index % colors.length]
  end

  def is_number?(string)
    true if Float(string) rescue false
  end
end
