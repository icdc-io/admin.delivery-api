Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
        # services
        get     '/services',                                  to: 'services#index' 
        post    '/services/:service_name/install',            to: 'services#create',                        constraints: { :service_name => /[0-z\.\-]+/ }
        delete  '/services/:service_name',                    to: 'services#delete',                        constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/services/:service_name',                    to: 'services#overview',                      constraints: { :service_name => /[0-z\.\-]+/ }
        put     '/services/:service_name/release',            to: 'services#upgrade',                       constraints: { :service_name => /[0-z\.\-]+/ }
        put     '/services/:service_name/downgrade',          to: 'services#downgrade',                     constraints: { :service_name => /[0-z\.\-]+/ }
  
        # versions
        get     '/services/:service_name/install',            to: 'versions#show',                          constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/services/:service_name/downgrade',          to: 'versions#get_downgrade_versions',        constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/services/:service_name/version',            to: 'versions#get_installed_github_versions', constraints: { :service_name => /[0-z\.\-]+/ }

        # updates
        put     '/services/:service_name/update',             to: 'updates#create',                          constraints: { :service_name => /[0-z\.\-]+/ }
        get     '/services/:service_name/update',             to: 'updates#show',                            constraints: { :service_name => /[0-z\.\-]+/ }

        # releases
        get     '/services/:service_name/release',            to: 'releases#show',                           constraints: { :service_name => /[0-z\.\-]+/ }

        # status
        get      '/statuses',            to: 'statuses#show'

    end
  end 
end