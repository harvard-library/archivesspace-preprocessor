Rails.application.routes.draw do
  scope "/ajax" do
    get "issues-per-repo", to: 'reports#issues_per_repo'
  end

  resources :runs,                 only: [:index, :show]
  resources :finding_aids,         only: [:index, :show], param: :eadid
  resources :finding_aid_versions, only: [:show],         param: :digest
  resources :schematrons,          only: [:index, :show], param: :digest

  root to: 'dashboards#index'
end
