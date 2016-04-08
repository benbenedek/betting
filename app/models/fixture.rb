require 'migration'

class Fixture < ActiveRecord::Base
  belongs_to :league
  has_many :matches

  def self.get_upcoming_fixture
    current_date = DateTime.now
    Fixture.where("date >= '#{current_date - 3.days}'").first
  end

  def find_game_by(home_team, away_team)
    matches.find { |match| match.home_team.id == home_team.id && match.away_team.id == away_team.id}
  end

  def all_games_dont_hava_scores?
    matches.find { |match| !match.has_score? }.present?
  end

  def has_any_scores?
    matches.find { |match| match.has_score? }.present?
  end

  def get_fixture_bet
    FixtureBet.find_by_fixture_id(self.id) || FixtureBet.create({ fixture_id: self.id })
  end

  def get_fixture_bet_for_user(user)
    return nil if user.nil?

    fb = get_fixture_bet
    fb.get_fixture_bet_for_user(user, matches)
  end

  def can_still_bet_on_fixture?
    tz = TZInfo::Timezone.get('Asia/Jerusalem')
    time_in_il = tz.now
    time_in_il < date || id == 29
  end
end
