class Team < ActiveRecord::Base
  has_many :home_matches, class_name: Match.to_s, :foreign_key => "home_team_id"
  has_many :away_matches, class_name: Match.to_s, :foreign_key => "away_team_id"
end
