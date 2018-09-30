module Migration
  extend self
  def get_team(team_name)
    team = Team.find_by_name(team_name)
    team = Team.create({name: team_name}) if team.nil?
    team
  end

  def run_migration
    league = League.find_by_name("Ligat ha al")
    (27..36).each { |idx|
      page_url = "http://football.org.il/Leagues/Pages/FullRoundGamesList.aspx?team_id=%D7%9B%D7%9C%20%D7%94%D7%A7%D7%91%D7%95%D7%A6%D7%95%D7%AA&round_number=#{idx}&league_id=-1"
      page = Nokogiri::HTML(RestClient.get(page_url))
      fixture = Fixture.create({number: idx})
      games_trs = page.css("tr[class='BDCItemStyle']") + page.css("tr[class='BDCItemAlternateStyle']")
      fixture_date = nil
      games_trs.each { |game_tr|
        date_str = game_tr.css("td[class='BDCItemText']")[1].text
        sp_date = date_str.split("/")
        sp_date[2] = "20" + sp_date[2]
        fixed_string = sp_date.join("-")
        p fixed_string
        fixture_date = DateTime.parse(fixed_string, '%d-%m-%Y')  if fixture_date.nil?
        home_team = get_team(game_tr.css("td[class='BDCItemText']")[2].css("a[class='BDCItemLink']")[0].text)
        away_team = get_team(game_tr.css("td[class='BDCItemText']")[2].css("a[class='BDCItemLink']")[1].text)
        fixture.matches.build({home_team: home_team, away_team: away_team})
      }
      fixture.date = fixture_date
      league.fixtures.push(fixture)
      league.save
    }
  end

  def fetch_season(league_id, season_id)
    new_league = League.create!(name: 'Ligat ha al', season: '2018/2019', id: 2)

    league_stats = Migration.get_league_stats

    teams = league_stats.css('div[class="league-table table-w-playoff"]').css('section[class="playoff-container"]').css('a')

    teams.each do |team|
      team_name = team.css('[class="table_col align_content team_name"]').children.last.text
      team_id = team.to_h['href'].split('team_id=').second.to_i
      Team.create!(name: team_name, association_id: team_id)
    end
  end

  def fetch_fixture(league_id, fixture_round)
    league = League.find_by_id(league_id)
    league_stats = get_round(fixture_round)
    games_wrapper = league_stats.css('div[class="table_view full_view results-grid results-home teams-table league-games"]')
    games = games_wrapper.css('a[class="table_row link_url"]')
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

        match = Match.where(fixture: fixture, home_team: home_team, away_team: away_team).first ||
          Match.new(fixture: fixture, home_team: home_team, away_team: away_team)

        match.date = game_date
        match.score = score
        match.save!
    end
    fixture.date = parsed_fixture_date
    fixture.save!
  end

  def get_round(round_id)
    uri = URI.parse("http://football.org.il/Components.asmx/League_AllTables")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/x-www-form-urlencoded; charset=UTF-8"
    request["Pragma"] = "no-cache"
    request["Origin"] = "http://football.org.il"
    request["Accept-Language"] = "en-US,en;q=0.9,he;q=0.8"
    request["User-Agent"] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'
    request["Accept"] = "*/*"
    request["Cache-Control"] = "no-cache"
    request["X-Requested-With"] = "XMLHttpRequest"
    request["Cookie"] = "ASP.NET_SessionIdNew=zox4duvf5ouzq5mzgkw5ghd3SazARfdmstkiHJXX+cmyLGRqQZk=; visid_incap_1491979=Da+iswq/Romx72oLKwCJRb9uqVsAAAAAQUIPAAAAAAB1+xrEjuPM9oxGW7pZV2qF; _ga=GA1.3.2014550527.1537830601; _gid=GA1.3.1618273930.1537830601; incap_ses_730_1491979=D5jrdjMsQhH8nqINvnshCvKjqVsAAAAAKDyw4A+fHOM0XcXsFhwFzw==; incap_ses_457_1491979=cnO8TeGOi0+f46i2K5hXBvgtqlsAAAAAr0pq+H/+cuAygV9qGuHhFg==; incap_ses_874_1491979=w6bzePFB7R4MKoZc1RIhDAUuqlsAAAAAW5zCIBtlP5MKTdp+086qeA==; __atuvs=5baa2dfb6ceb382b002"
    request["Connection"] = "keep-alive"
    request["Referer"] = "http://football.org.il/leagues/league/?league_id=40&season_id=20"
    request.set_form_data({
      "box" => "10",
      "language" => "-1",
      "league_id" => "40",
      "round" => round_id,
      "season_id" => "20"
    })

    req_options = { use_ssl: false }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }

    Nokogiri::HTML(response.body)
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
