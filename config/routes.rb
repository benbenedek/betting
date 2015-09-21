Rails.application.routes.draw do
  get    'login'   => 'sessions#new'
  post   'login'   => 'sessions#create'
  get    'logout'  => 'sessions#destroy'

  get 'signup' => 'users#new'

  resources :users

  get 'scores'   => 'application#scoretable'
  post "/place_bet/:match_bet_id" => 'application#place_bet', format: :js
  get "/:number" => 'application#index', as: 'index'

  root 'application#index'

end
