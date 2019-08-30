fixtures = Fixture.where(league_id: 3)
kofiko = User.find(4)
fixtures.each do |fixture|
    bets = fixture.get_fixture_bet_for_user(kofiko)
    bets.bets.each do |b|
        puts("kofiko bet #{b}")
        b.prediction = ['X', '1', '2'].sample
        b.save!
    end
    
end