Rails.application.routes.draw do
  get    'login'   => 'sessions#new'
  post   'login'   => 'sessions#create'
  get    'logout'  => 'sessions#destroy'

  get 'signup' => 'users#new'

  resources :users

  # ============================================
  # CLASSIC ERB ROUTES - Available at /classic
  # ============================================
  scope '/classic' do
    get '/scores'                       => 'scores#scoretable', league_id: 10, as: 'classic_scores'
    get '/scores/:league_id'            => 'scores#scoretable', as: 'classic_scoretable'
    get '/scorescsv/:league_id'         => 'scores#scoretablecsv', as: 'scoretablecsv'
    post "/place_bet/:match_bet_id"     => 'bets#place_bet', format: :js
    get "/:league_id/:number"           => 'bets#index', as: 'classic_index'
    get "/open_close/:league_id/:number/:should_open"  => 'bets#open_close', as: 'open_close'
    get "/migration/:league_id/:number/"  => 'bets#run_migration', as: 'run_migration'
    get '/'                             => 'bets#index', as: 'classic_root'
  end

  # ============================================
  # REACT ROUTES - Now the default
  # ============================================
  get '/bets',                      to: 'react#bets', as: 'react_bets'
  get '/bets/:league_id/:number',   to: 'react#bets', as: 'react_bets_league'
  get '/scores',                    to: 'react#scores', as: 'react_scores'
  get '/scores/:league_id',         to: 'react#scores', as: 'react_scores_league'

  # Root route - React is now default
  root 'react#index'

  # ============================================
  # API ROUTES - For React to fetch data
  # ============================================
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Fixtures - specific routes MUST come before parameterized routes
      get '/fixtures/current',              to: 'fixtures#current'
      get '/fixtures/:id/all_bets',         to: 'fixtures#all_bets'
      post '/fixtures/:id/toggle_open',     to: 'fixtures#toggle_open'
      post '/fixtures/:league_id/:number/run_migration', to: 'fixtures#run_migration'
      get '/fixtures/:league_id/:number',   to: 'fixtures#show'

      # Bets
      patch '/bets/:id',                    to: 'bets#update'

      # Users
      get '/users/current',                 to: 'users#current'

      # Scores
      get '/scores',                        to: 'scores#show'
      get '/scores/:league_id',             to: 'scores#show'
    end
  end

  # Catch-all for React Router (client-side routing) - must be last
  get '*path', to: 'react#index', constraints: lambda { |req|
    # Don't catch API routes, classic routes, or asset requests
    !req.path.start_with?('/api/') &&
    !req.path.start_with?('/classic/') &&
    !req.path.start_with?('/assets/') &&
    !req.path.start_with?('/react-assets/') &&
    !req.path.start_with?('/login') &&
    !req.path.start_with?('/logout') &&
    !req.path.start_with?('/signup') &&
    !req.path.start_with?('/users')
  }

end
