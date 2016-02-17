Rails.application.routes.draw do
  scope "/ajax" do
    get "issues-per-repo", to: 'reports#issues_per_repo'
  end

  root to: 'dashboards#index'
end
