require 'devise_token_auth'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    mount_devise_token_auth_for 'User', at: 'auth'#, skip: [:sessions, :registrations]
    resources :contests, param: :slug, only: [:index, :show] do
      resources :tasks, param: :slug, only: [:show]
    end
  end
  match '*path' => 'application#render_404', via: [:get, :post, :put, :patch, :delete, :options, :head]
end
