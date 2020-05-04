require 'devise_token_auth'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    mount_devise_token_auth_for 'User', at: 'auth'#, skip: [:sessions, :registrations]
    namespace :manage do
      resources :contests, param: :slug, only: [:index, :show]
      resources :problems, param: :slug, only: [] do
        collection do
          get 'unset_problems'
        end
      end
    end
    resources :contests, param: :slug, except: [:destroy] do
      get "submits" => "submits#me"
      get "submits/all" => "submits#all"
      resources :tasks, param: :slug, only: [:show] do
        post "submit" => "submits#create"
        put 'remove_from_contest' => 'tasks#remove_from_contest'
      end
      get 'standings' => 'standings#index'
      member do
        put 'set_task'
      end
    end
    resources :problems, except: [:destroy] do
      resources :testcases, only: [:index, :show, :create, :destroy] do
        collection do
          post 'upload'
        end
        member do
          patch 'change_state'
        end
      end
      resources :testcase_sets, only: [:create, :destroy]
    end
  end
  match '*path' => 'application#render_404', via: [:get, :post, :put, :patch, :delete, :options, :head]
end
