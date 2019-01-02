module BetsHelper
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
end
