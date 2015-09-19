class LeagueBet < ActiveRecord::Base
  belongs_to :league
  has_many :fixture_bets
end
