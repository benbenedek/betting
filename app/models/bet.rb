class Bet < ActiveRecord::Base
  belongs_to :match, :class_name => Match.to_s
  belongs_to :user_bet, :class_name => UserBet.to_s
end
