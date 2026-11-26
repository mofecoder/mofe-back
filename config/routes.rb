require 'devise_token_auth'

Rails.application.routes.draw do
  match '*path' => 'preflight_request#preflight', via: :options
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :public do
    scope :v1 do

    end
  end

  namespace :api do
    mount_devise_token_auth_for 'User', at: 'auth', controllers: {
      passwords: 'api/passwords'
    }
    get 'top' => 'top_page#index'
    namespace :manage do
      resources :contests, param: :slug, only: [:index, :show]
      resources :problems, param: :slug, only: [] do
        collection do
          get 'unset_problems'
        end
      end
    end
    # Slack 連携 (writer 権限の付与) は現在使っていないため無効化している。
    # 外部から叩ける入口を減らすためで、コントローラ (Api::Slack::SlackController) は残してある。
    # 再び使う場合はここを戻し、Slack の署名検証が有効なことを確認すること。
    # namespace :slack do
    #   post 'add_writer' => 'slack#add_writer'
    # end
    resources :contests, param: :slug, except: [:destroy] do
      resources :submissions, only: [:index, :show] do
        collection do
          get 'all'
          get 'team'
        end
        member do
          patch 'toggle_published'
        end
      end
      resources :tasks, param: :slug, only: [:show] do
        post 'submit' => 'submissions#create'
        put 'remove_from_contest' => 'tasks#remove_from_contest'
        put 'move' => 'tasks#move'
      end
      post 'contest_admins', to: 'contest_admins#create'
      delete 'contest_admins', to: 'contest_admins#destroy'
      get 'standings' => 'standings#index'
      member do
        put 'set_task'
      end
      resources :clarifications, only: [:index, :show, :create, :update]
      resources :registrations, only: [:create] do
        collection do
          post 'team'
          delete :index, to: 'registrations#delete'
        end
      end

      post 'rejudge'
    end
    resources :problems, except: [:destroy] do
      resources :testcases, only: [:index, :show, :create, :destroy, :update] do
        collection do
          post 'upload'
          delete 'delete_multiple'
          patch 'change_state_multiple'
        end
        member do
          patch 'change_state'
        end
      end
      resources :testcase_sets, only: [:create, :show, :update, :destroy]
      resource :tester_relations, only: [:create] do
      end
      delete 'tester_relations', to: 'tester_relations#destroy'
      get 'checker' => 'problems#download_checker'
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

  namespace :v4 do
    resources :problems
    resources :uploads, only: %i[index create destroy] do
      member do
        post 'complete'
      end
    end
  end

  match '/' => 'application#render_404', via: [:get, :post, :put, :patch, :delete, :head]
  match '*' => 'application#render_404', via: [:get, :post, :put, :patch, :delete, :head]
end
