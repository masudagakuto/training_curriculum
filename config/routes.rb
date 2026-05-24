Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'calendars#index'
  resources :calendars

  # お金のやり取り記録
  resources :money_transactions, only: [:index, :create, :destroy]

  # LINE Webhook エンドポイント
  post '/line/callback', to: 'line_webhooks#callback'
end
