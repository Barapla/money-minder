# frozen_string_literal: true

Rails.application.routes.draw do
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

  root 'home#index'
end
