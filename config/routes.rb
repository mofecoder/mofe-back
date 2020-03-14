require 'devise_token_auth'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    mount_devise_token_auth_for 'User', at: 'auth'#, skip: [:sessions, :registrations]
    resources :contests, param: :slug, except: [:destroy] do
      get "submits" => "submits#me"
      get "submits/all" => "submits#all"
      resources :tasks, param: :slug, only: [:show] do
        post "submit" => "submits#create"
      end
      get 'standings' => 'standings#index'
      member do
        put 'set_task'
      end
    end
  end
  match '*path' => 'application#render_404', via: [:get, :post, :put, :patch, :delete, :options, :head]
end
