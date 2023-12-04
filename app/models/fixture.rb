require 'migration'

class Fixture < ActiveRecord::Base
  belongs_to :league, :class_name => League.to_s
  has_many :matches, :class_name => Match.to_s
  has_many :fixture_bets, :class_name => FixtureBet.to_s

  def self.get_upcoming_fixture
    current_date = DateTime.now
    Fixture.where("date >= '#{current_date - 3.days}'").includes({ :matches => [:away_team, :home_team]}).first
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
    FixtureBet.where(fixture_id: self.id).first || FixtureBet.create({ fixture_id: self.id })
  end

  def get_fixture_bet_for_user(user)
    return nil if user.nil?

    fb = get_fixture_bet
    fb.get_fixture_bet_for_user(user, matches)
  end

  def default_timezone
    TZInfo::Timezone.get('Asia/Jerusalem')
  end

  def seconds_left_to_bet
    last_bet_date_from_matches - default_timezone.now
  end

  def last_bet_date_from_matches
    matches.map { |m| m.last_bet_date }.min
  end

  def last_bet_date
    (date - 3.hours).in_time_zone(default_timezone)
  end

  def can_still_bet_on_fixture?
    default_timezone.now < last_bet_date || self.is_open
  end

  def get_previous_scores
    previous_matches = {}
    matches.each do |match|
      match_ids = [match.away_team_id, match.home_team_id].sort
      matches = Rails.cache.fetch("prev_matches_#{@match_ids.to_s}", :expires_in => 12.hours) do
        Match.includes(:away_team, :home_team).where("(home_team_id = ? AND away_team_id = ?) OR (away_team_id = ? AND home_team_id = ?)", match.away_team_id, match.home_team_id, match.away_team_id, match.home_team_id).where.not(score: [nil, ""], date: nil, id: match.id).where("date < ?", match.date).order('date DESC')
      end
      previous_matches[match.id] = matches
    end
    previous_matches
  end
end
