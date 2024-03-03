require 'devise_token_auth'

Rails.application.routes.draw do
  match '*path' => 'preflight_request#preflight', via: :options
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    mount_devise_token_auth_for 'User', at: 'auth', controllers: {
      passwords: 'api/passwords'
    }
    namespace :manage do
      resources :contests, param: :slug, only: [:index, :show]
      resources :problems, param: :slug, only: [] do
        collection do
          get 'unset_problems'
        end
      end
    end
    namespace :slack do
      post 'add_writer' => 'slack#add_writer'
    end
    resources :contests, param: :slug, except: [:destroy] do
      resources :submissions, only: [:index, :show] do
        collection do
          get 'all'
        end
      end
      resources :tasks, param: :slug, only: [:show] do
        post "submit" => "submissions#create"
        put 'remove_from_contest' => 'tasks#remove_from_contest'
      end
      post 'contest_admins', to: 'contest_admins#create'
      delete 'contest_admins', to: 'contest_admins#destroy'
      get 'standings' => 'standings#index'
      member do
        put 'set_task'
      end
      resources :clarifications, only: [:index, :show, :create, :update]
      post 'register'
      delete 'unregister'
      post 'rejudge'
    end
    resources :problems, except: [:destroy] do
      resources :testcases, only: [:index, :show, :create, :destroy, :update] do
        collection do
          post 'upload'
          delete 'delete_multiple'
        end
        member do
          patch 'change_state'
        end
      end
      resources :testcase_sets, only: [:create, :show, :update, :destroy]
      resource :tester_relations, only: [:create] do
      end
      delete 'tester_relations', to: 'tester_relations#destroy'
      post 'checker' => 'problems#update_checker'
    end
    resources :users, only: [:index, :update] do
      collection do
        post 'update_rating'
      end
      member do
        patch 'update_admin' => 'users#update_admin'
        post 'generate_writer_request_code'
      end
    end
    resources :posts
  end
  match '/' => 'application#render_404', via: [:get, :post, :put, :patch, :delete, :head]
  match '*' => 'application#render_404', via: [:get, :post, :put, :patch, :delete, :head]
end
