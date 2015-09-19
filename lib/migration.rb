module Migration
  extend self
  def get_team(team_name)
    team = Team.find_by_name(team_name)
    team = Team.create({name: team_name}) if team.nil?
    team
  end

  def run_migration
    league = League.create({name: "Ligat ha al", season: "2015/2016"})
    (1..26).each { |idx|
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

  def get_scores_for_fixture_id(id)
    fixture = Fixture.find(id)
    return if fixture.nil?

    page_url = "http://football.org.il/Leagues/Pages/FullRoundGamesList.aspx?team_id=%D7%9B%D7%9C%20%D7%94%D7%A7%D7%91%D7%95%D7%A6%D7%95%D7%AA&round_number=#{fixture.number}&league_id=-1"
    page = Nokogiri::HTML(RestClient.get(page_url))
    games_trs = page.css("tr[class='BDCItemStyle']") + page.css("tr[class='BDCItemAlternateStyle']")
    games_trs.each { |game_tr|
      home_team = get_team(game_tr.css("td[class='BDCItemText']")[2].css("a[class='BDCItemLink']")[0].text)
      away_team = get_team(game_tr.css("td[class='BDCItemText']")[2].css("a[class='BDCItemLink']")[1].text)
      next if home_team.nil? || away_team.nil?
      match = fixture.find_game_by(home_team, away_team)
      next if match.nil?
      score = game_tr.css("td[class='BDCItemText']")[4].text
      next unless score.include?('-')
      match.score = score
      match.save
    }
  end
end
