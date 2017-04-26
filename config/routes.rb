Rails.application.routes.draw do

  resources :display_configurations
  root 'studies#index'
  resources :annotations
  resources :reviews
  resources :tags

  get '/.well-known/acme-challenge/:id' => 'pages#letsencrypt'
  get 'pages/about'
  get 'pages/contact'

  devise_for :users do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  resources :studies do
    collection do
      get 'search'
    end
    resources :reviews, except: [:index]
  end

end
