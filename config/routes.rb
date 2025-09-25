Rails.application.routes.draw do
  namespace :mcp do
    namespace :v20250618 do
      get "/", { controller: :application, action: :index }
      post "/", { controller: :application, action: :index }
    end
  end
  
  namespace :fhir do
    namespace :r4 do
      get "metadata", { controller: :metadata, action: :index }

      get "Patient/:uuid", to: "patients#show", as: :patient
      get "Patient", to: "patients#index", as: :patients
    end
  end

  # Alias patients resource to patient_records
  resources :patients, controller: "patient_records"
  resources :patient_records

  get "pages/index"
  root to: "pages#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
