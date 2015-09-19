class UserBet < ActiveRecord::Base
  belongs_to :user
  belongs_to :fixture_bet
  has_many :bets
end
