# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  resources :obligatory_payments
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")

  resources :budgets do
    collection do
      post :change_budget_type
      post :budgets_table
    end

    member do
      post :show_transactions
    end
  end

  resources :transactions do
    collection do
      post :change_categories
      post :transactions_table
    end
  end

  resources :recurring_transactions, only: %i[create] do
    collection do
      get :new_modal
    end
  end

  resources :calendar, only: [:index] do
    collection do
      post :set_month
      get :day_details
      get :advanced_search
    end
  end

  resources :obligatory_payments_calendar, only: [:index], path: 'obligatory-payments-calendar' do
    collection do
      post :set_month
      get :day_details
    end
  end

  resources :reports, only: [:index] do
    collection do
      post :distribution_chart
      post :flow_chart
      post :main_data
      post :comparison_chart
    end
  end

  # destroy excluido intencionalmente: cada usuario tiene una sola información laboral permanente
  resource :employment_information, only: %i[show new create edit update]
  resource :payroll_profile, only: %i[edit update]

  namespace :api do
    namespace :v1 do
      resources :payroll_calculations, only: [] do
        collection do
          get :aguinaldo
          get :savings_fund
          get :net_salary
        end
      end
    end
  end

  resources :financial_insights, only: [] do
    collection do
      post :generate
      get :raw_data # Para debugging
    end
  end

  # sidekiq routes
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  root 'home#index'
end
