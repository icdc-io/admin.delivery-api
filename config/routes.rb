Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # services
      get '/services', to: 'services#index'
      get '/services/:service_name', to: 'services#show', constraints: { :service_name => /[0-z\.]+/ }
      get '/services/:service_name/overview', to: 'services#overview', constraints: { :service_name => /[0-z\.]+/ }
      post '/services/:service_name', to: 'services#create', constraints: { :service_name => /[0-z\.]+/ }
      put '/services/:service_name', to: 'services#upgrade', constraints: { :service_name => /[0-z\.]+/ }
      delete '/services/:service_name', to: 'services#delete', constraints: { :service_name => /[0-z\.]+/ }

      # versions
      get '/services/:service_name/version', to: 'versions#show', constraints: { :service_name => /[0-z\.]+/ }
      put '/services/:service_name/version', to: 'versions#create', constraints: { :service_name => /[0-z\.]+/ }
      get '/services/:service_name/installed_versions', to: 'versions#get_downgrade_versions', constraints: { :service_name => /[0-z\.]+/ }
      get '/services/:service_name/service_versions', to: 'versions#get_installed_github_versions', constraints: { :service_name => /[0-z\.]+/ }

      # updates
      put '/services/:service_name/update', to: 'updates#create', constraints: { :service_name => /[0-z\.]+/ }
      get '/services/:service_name/update', to: 'updates#show', constraints: { :service_name => /[0-z\.]+/ }

      # releases
      put '/services/:service_name/release', to: 'releases#create', constraints: { :service_name => /[0-z\.]+/ }
      get '/services/:service_name/release', to: 'releases#show', constraints: { :service_name => /[0-z\.]+/ }

      # status
      get '/services/:service_name/status', to: 'statuses#show', constraints: { :service_name => /[0-z\.]+/ }
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
