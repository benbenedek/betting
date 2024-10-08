Rails.application.routes.draw do
  get    'login'   => 'sessions#new'
  post   'login'   => 'sessions#create'
  get    'logout'  => 'sessions#destroy'

  get 'signup' => 'users#new'

  resources :users

  get '/scores'                       => 'scores#scoretable', league_id: 9
  get '/scores/:league_id'            => 'scores#scoretable', as: 'scoretable'
  get '/scorescsv/:league_id'         => 'scores#scoretablecsv', as: 'scoretablecsv'
  post "/place_bet/:match_bet_id"     => 'bets#place_bet', format: :js
  get "/:league_id/:number"           => 'bets#index', as: 'index'

  get "/open_close/:league_id/:number/:should_open"  => 'bets#open_close', as: 'open_close'

  get "/migration/:league_id/:number/"  => 'bets#run_migration', as: 'run_migration'

  root 'bets#index'

end
