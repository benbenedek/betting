require 'nokogumbo'

module Migration
  extend self
  def get_team(team_name)
    team = Team.find_by_name(team_name)
    team = Team.create({name: team_name}) if team.nil?
    team
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
end
