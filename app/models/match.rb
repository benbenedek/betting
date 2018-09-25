class Match < ActiveRecord::Base
  belongs_to :fixture

  belongs_to :home_team, class_name: Team, :foreign_key => "home_team_id"
  belongs_to :away_team, class_name: Team, :foreign_key => "away_team_id"

  def home_info
    home_team.name
  end

  def away_info
    away_team.name
  end

  def bet_score
    return "" unless has_score?
    home_score = home_team_score.to_i
    away_score = away_team_score.to_i

    if home_score > away_score
      return "1"
    elsif away_score > home_score
      return "2"
      end
    "X"
  end

  def has_score?
    score.present?
  end

  private

  def home_team_score
    score.split('-')[1]
  end

  def away_team_score
    score.split('-')[0]
  end

end
