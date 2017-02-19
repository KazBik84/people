Hrguru::Application.routes.draw do
  resources :user_skill_rates, only: [:index, :update]
  resources :skills
  devise_for :users



  authenticated :user do
    root 'users#index', as: 'listing'
  end

  resources :scheduling, only: [:index], path: 'scheduling' do
    get nil, on: :collection, to: 'scheduling#all'
    get 'all', on: :collection
    get 'juniors_and_interns', on: :collection
    get 'to_rotate', on: :collection
    get 'in_internals', on: :collection
    get 'with_rotations_in_progress', on: :collection
    get 'in_commercial_projects_with_due_date', on: :collection
    get 'booked', on: :collection
    get 'unavailable', on: :collection
    get 'not_scheduled', on: :collection
  end

  namespace :api do
    scope module: :v1 do
      resources :users, only: [:index, :show, :contract_users]
      resources :projects, only: [:index]
      resources :roles, only: [:index]
      resources :memberships, except: [:new, :edit]
    end

    namespace :v2 do
      resources :users, only: [:index]
      resources :statistics, only: [:index]
      resources :skills, only: [:index]
      resources :user_skill_rates, only: [:index]
    end

    namespace :v3 do
      resources :user_skill_rates, only: :index
      resources :users, only: [] do
        get :technical, on: :collection
      end
    end
  end

  resources :users, only: [:index, :show, :update] do
    get :skills_history, on: :member, to: 'users/user_skill_rates#history'
  end
  resources :dashboard, only: [:index], path: 'dashboard' do
    get 'active', on: :collection
    get 'potential', on: :collection
    get 'archived', on: :collection
  end
  resources :projects, except: [:index]
  resources :memberships, except: [:show]
  resources :teams
  resources :notes, except: [:index]
  resources :roles do
    post 'sort', on: :collection
  end
  resources :positions, except: [:index, :show] do
    member do
      put :toggle_primary
    end
  end
  resources :abilities
  resources :settings, only: [:update]
  get '/settings', to: 'settings#edit'
  root 'welcome#index'

  scope '/styleguide' do
    get '/css', to: 'pages#css'
    get '/components', to: 'pages#components'
  end

  resources :statistics, only: [:index]

  resources :features, only: [:index] do
    resources :strategies, only: [:update, :destroy]
  end

  resources :project_info, param: :name, only: [:show, :index]

  mount Flip::Engine => '/features'
end
