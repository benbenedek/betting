Rails.application.routes.draw do
  get    'login'   => 'sessions#new'
  post   'login'   => 'sessions#create'
  get    'logout'  => 'sessions#destroy'

  get 'signup' => 'users#new'

  resources :users

  get '/scores'                       => 'scores#scoretable', league_id: 2
  get '/scores/:league_id'            => 'scores#scoretable', as: 'scoretable'
  post "/place_bet/:match_bet_id"     => 'bets#place_bet', format: :js
  get "/:league_id/:number"           => 'bets#index', as: 'index'

  root 'bets#index'

end
