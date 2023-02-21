class FixtureBet < ActiveRecord::Base
  belongs_to :fixture
  has_many :user_bets

  def get_fixture_bet_for_user(user, matches)
    return nil if user.nil?
    current_user_betting = user_bets.where("user_id = #{user.id}").first
    return current_user_betting if current_user_betting.present?

    current_user_bets = user_bets.build({ user_id: user.id })
    matches.each { |match|
      current_user_bets.bets.build({ match: match, prediction: "X"})
    }
    self.save!
    current_user_bets
  end
end
