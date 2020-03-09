Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    resources :contests, param: :slug, only: [:index, :show] do
      resource :submits, only: [:show] do
        resource :all, only: [:show]
      end
      resources :tasks, param: :slug, only: [:show] do
        resource :submit, only: [:create]
      end
    end
  end
end
