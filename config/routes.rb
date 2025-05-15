Rails.application.routes.draw do

  get '/up', to: proc { [200, {}, ['Up!']] }

  namespace :api do
    namespace :v1 do
        # status
        get      '/services/status',            to: 'statuses#show'
        get      '/services/apps',              to: 'statuses#apps'
        
        # services
        get     '/services',                                 to: 'services#index'
        get     '/services/:service_name',                   to: 'services#show'
        post    '/service/:service_name/install',            to: 'services#create',                        constraints: { :service_name => /[0-z\.\-]+/ }
        delete  '/service/:service_name',                    to: 'services#delete',                        constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/service/:service_name',                    to: 'services#overview',                      constraints: { :service_name => /[0-z\.\-]+/ }
        put     '/service/:service_name/release',            to: 'services#upgrade',                       constraints: { :service_name => /[0-z\.\-]+/ }
        put     '/service/:service_name/downgrade',          to: 'services#downgrade',                     constraints: { :service_name => /[0-z\.\-]+/ }

        # versions
        get     '/service/:service_name/install',            to: 'versions#show',                          constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/service/:service_name/downgrade',          to: 'versions#get_downgrade_versions',        constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/service/:service_name/version',            to: 'versions#get_installed_github_versions', constraints: { :service_name => /[0-z\.\-]+/ }

        # updates
        put     '/service/:service_name/update',             to: 'updates#create',                          constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/service/:service_name/update',             to: 'updates#show',                            constraints: { :service_name => /[0-z\.\-]+/ }

        # releases
        get     '/service/:service_name/release',            to: 'releases#show',                           constraints: { :service_name => /[0-z\.\-]+/ }

    end
  end
end
