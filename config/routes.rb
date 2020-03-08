Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    resources :contests, param: :slug, only: [:index, :show] do
      resources :tasks, param: :slug, only: [:show]
    end
  end
end
