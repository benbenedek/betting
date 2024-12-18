# require 'nokogumbo'

module Migration
  extend self
  def get_team(team_name)
    team = Team.find_by_name(team_name)
    team = Team.create({name: team_name}) if team.nil?
    team
  end

  def fetch_fixture_one(league_id, fixture_round)
    league = League.find_by_id(league_id)
    round_games = fetch_and_parse_one_json().select!{ |x| x.fetch('round', {}).fetch('ID', -1) == fixture_round }
    Rails.logger.error "During migration got result #{round_games}"

    parsed_fixture_date = DateTime.parse(round_games.first['date'])
    fixture = Fixture.where(league: league, number: fixture_round).first ||
        Fixture.new(league: league, date: parsed_fixture_date, number: fixture_round)

    round_games.each do |game|
        game_date = game['date']
        parsed_fixture_date = DateTime.parse(game_date) if parsed_fixture_date > DateTime.parse(game_date)

        score = nil
        home_team_score = game['homeScore']
        away_team_score = game['guestScore']
        if game['isHaveScore']
          score = "#{away_team_score}-#{home_team_score}"
        end

        home_team_id = game['homeId']
        away_team_id = game['guestId']
        home_team = Team.where(one_id: home_team_id).first
        away_team = Team.where(one_id: away_team_id).first
        if (home_team.nil? || away_team.nil?)
          puts "We have an error!! #{home_team} (#{home_team_id}) - #{away_team} (#{away_team_id})"
          return
        end

        match = Match.where(fixture: fixture, home_team: home_team, away_team: away_team).first ||
          Match.new(fixture: fixture, home_team: home_team, away_team: away_team)

        match.date = game_date
        match.score = score
        match.save!
        p match
    end
    fixture.date = parsed_fixture_date
    fixture.save!
  end

  def print_all_matches(round_number)
    res = fetch_and_parse_one_json()
    res.select!{ |x| x['round'] == round_number }.each do |match|
      p "#{match['roundName']} #{match['homeName']} #{match['homeScore']} - #{match['guestName']} #{match['guestScore']}"
    end
  end

  def print_teams_and_ids()
    res = fetch_and_parse_one_json()
    map = {}
    res.each do |game|
      map[game['homeName']] = map[game['homeName']]  || []
      map[game['homeName']] << game['homeId']
    end

    map
  end

  def fetch_and_parse_one_json()
    uri = URI.parse("https://www.one.co.il/cat/leagues/AjaxActions.ashx?a=get-matches&season=24-25&l=1")
    request = Net::HTTP::Get.new(uri)
    request["Sec-Ch-Ua"] = "\"Google Chrome\";v=\"119\", \"Chromium\";v=\"119\", \"Not?A_Brand\";v=\"24\""
    request["Accept"] = "application/json, text/javascript, */*; q=0.01"
    request["Referer"] = "https://www.one.co.il/Soccer/League/1"
    request["X-Requested-With"] = "XMLHttpRequest"
    request["Sec-Ch-Ua-Mobile"] = "?0"
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    request["Sec-Ch-Ua-Platform"] = "\"macOS\""

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    # response.code
    JSON.parse(response.body)
  end

  def fetch_fixture(league_id, fixture_round)
    league = League.find_by_id(league_id)
    league_stats_str = get_round(league.association_id ,fixture_round)
    Rails.logger.error "During migration got result #{league_stats_str}"
    start_idx = league_stats_str.index("<HtmlData>") + "<HtmlData>".length
    html = league_stats_str[start_idx, league_stats_str.index('</HtmlData>') - start_idx]
    res = Nokogiri::HTML(CGI.unescapeHTML("&lt;html&gt;&lt;body&gt;#{html}&lt;/body&gt;&lt;/html&gt;"))
    games_wrapper = res.css('div[class="table_view full_view results-grid results-home teams-table league-games"]')
    games = games_wrapper.css('a[class="table_row link_url"]')
    if games.empty?
      games = games_wrapper.css('div[class="table_row"]')
    end
    first_game = games.first
    fixture_date = first_game.children.first.children[1].text
    parsed_fixture_date = DateTime.parse(fixture_date, '%d/%m/%Y')
    fixture = Fixture.where(league: league, number: fixture_round).first ||
        Fixture.new(league: league, date: parsed_fixture_date, number: fixture_round)

    games.each do |game|
        game_date = game.children.first.children[1].text
        parsed_fixture_date = DateTime.parse(game_date, '%d/%m/%Y') if parsed_fixture_date > DateTime.parse(game_date, '%d/%m/%Y')

        score_node = game.css('div[class="table_col ltr result"]')
        score = nil
        if score_node.any? && score_node.children.count > 1
          score = score_node.children.last.text.gsub(' ', '')
        end
        content = game.to_h
        home_team_id = content['data-team1'].to_i
        away_team_id = content['data-team2'].to_i
        home_team = Team.where(association_id: home_team_id).first
        away_team = Team.where(association_id: away_team_id).first
        if (home_team.nil? || away_team.nil?)
          puts "We have an error!! #{home_team} (#{home_team_id}) - #{away_team} (#{away_team_id})"
          return
        end

        match = Match.where(fixture: fixture, home_team: home_team, away_team: away_team).first ||
          Match.new(fixture: fixture, home_team: home_team, away_team: away_team)

        match.date = game_date
        match.score = score
        match.save!
        # p match
    end
    fixture.date = parsed_fixture_date
    fixture.save!
  end

  def get_round(association_season_id,round_id)
    uri = URI.parse("https://www.football.org.il//Components.asmx/League_AllTables?league_id=40&season_id=#{association_season_id}&box=0&round_id=#{round_id.to_s}")
    request = Net::HTTP::Get.new(uri)
    request["Authority"] = "www.football.org.il"
    request["Pragma"] = "no-cache"
    request["Cache-Control"] = "no-cache"
    request["Sec-Ch-Ua"] = "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"98\", \"Google Chrome\";v=\"98\""
    request["Accept"] = "*/*"
    request["X-Requested-With"] = "XMLHttpRequest"
    request["Sec-Ch-Ua-Mobile"] = "?0"
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36"
    request["Sec-Ch-Ua-Platform"] = "\"macOS\""
    request["Sec-Fetch-Site"] = "same-origin"
    request["Sec-Fetch-Mode"] = "cors"
    request["Sec-Fetch-Dest"] = "empty"
    request["Referer"] = "https://www.football.org.il/leagues/league/?league_id=40&season_id=#{association_season_id}"
    request["Accept-Language"] = "en-US,en;q=0.9,he-IL;q=0.8,he;q=0.7"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    response.body.to_s
  end

  def get_league_stats(round = 1)
    uri = URI.parse("http://football.org.il/leagues/league/?league_id=40&season_id=20")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/x-www-form-urlencoded; charset=UTF-8"
    request["Pragma"] = "nLanguage: en-US,en;q=0.9,he;q=0.8"
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36"
    request["Accept"] = "*/*"
    request["Cache-Control"] = "no-cache"
    request["X-Requested-With"] = "XMLHttpRequest"
    request["Cookie"] = "ASP.NET_SessionIdNew=zox4duvf5ouzq5mzgkw5ghd3SazARfdmstkiHJXX+cmyLGRqQZk=; visid_incap_1491979=Da+iswq/Romx72oLKwCJRb9uqVsAAAAAQUIPAAAAAAB1+xrEjuPM9oxGW7pZV2qF; incap_ses_730_1491979=cAGiMs2noi3nI2oNvnshCsRuqVsAAAAAAevyHW4Bk/j6mkb4W1TROQ==; incap_ses_457_1491979=J+alabf5xCXm2g61K5hXBsVuqVsAAAAA1pCpLA3QNyoYPeDIBV4rng==; _ga=GA1.3.2014550527.1537830601; _gid=GA1.3.1618273930.1537830601; __atssc=google%3B2; __atuvc=4%7C39; __atuvs=5ba96ecaba211a60003"
    request["Connection"] = "keep-alive"
    request["Referer"] = "http://football.org.il/leagues/league/?league_id=40&season_id=20"
    request.set_form_data(
      "language" => "-1",
      "league_id" => "40",
      "round" => round,
      "season_id" => "20",
    )

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    Nokogiri::HTML(response.body)
  end

  def delete_fixture(fixture_id)
    fixture = Fixture.find(fixture_id)
    fixture.destroy!
    fixture_bet = FixtureBet.where(fixture: fixture)
    fixture_bet.each do |curr_fixture_bet|
      user_bets = UserBet.where(fixture_bet: curr_fixture_bet)
      user_bets.each do |curr_user_bet|
        curr_user_bet.destroy!
      end
      curr_fixture_bet.destroy!
    end

    matches = Match.where(fixture: fixture)
    matches.each do |match|
      bets = Bet.where(match: match)
      bets.each do |curr_bet|
        curr_bet.destroy!
      end
      match.destroy!
    end
  end

  def FixMissingBets(fixture)
    fixture_bet = FixtureBet.where({fixture: fixture}).first
    User.all.each do |user|
      user_bets = UserBet.where({user: user, fixture_bet: fixture_bet}).first
      if user_bets.nil?
        user_bets = UserBet.new({user: user, fixture_bet: fixture_bet})
        user_bets.save!
        user_bets.reload
      end
      user_bets = UserBet.where({user: user, fixture_bet: fixture_bet}).first
      if user_bets.nil?
        p "SOMETHING WENT WRONG"
        return
      end
      fixture.matches.each do |match|
        user_bet = user_bets.bets.where({match: match}).first
        if user_bet.present?
          p "PRESENT"
        else
          user_bets.bets.build({ match: match, prediction: "X"})
        end
      end
      user_bets.save!
      fixture_bet.save!
    end
  end
end
