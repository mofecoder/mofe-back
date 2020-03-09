Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    resources :contests, param: :slug, only: [:index, :show] do
      resource :submits, only: [:show] do
        get "all" => "alls#show"
      end
      resources :tasks, param: :slug, only: [:show] do
        post "submit" => "submits#create"
      end
    end
  end
end
