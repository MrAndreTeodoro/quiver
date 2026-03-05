Rails.application.routes.draw do
  root "job_offers#index"

  resources :job_offers do
    member do
      post :parse
      post :score
      post :generate
    end
  end

  resource :profile, only: [ :show, :edit, :update ]

  resources :applications, only: [ :show, :update ] do
    member do
      get :download_cv_md
      get :download_cv_docx
      get :download_cv_pdf
      get :download_cover_letter_md
      get :download_cover_letter_docx
      get :download_cover_letter_pdf
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
