# frozen_string_literal: true

class Template
  module Params
    def template_with_updated_params(template, applications, version, namespace)
      whitelist = build_whitelist(applications, namespace)
      template['parameters'].each do |param|
        next unless whitelist.include?(param['name'])

        update_param_value(param, applications, version, namespace)
      end
      template
    end

    private

    def build_whitelist(applications, namespace)
      base_whitelist = %w[VERSION APPLICATION_DOMAIN NAMESPACE REGISTRY_SERVER REGISTRY_PROXY_SERVER NAMESPACE_PREFIX]
      @configmaps_env_loc = OkdClient.configmaps_env_loc(namespace)
      base_whitelist << 'LOCATION_DOMAIN' if @configmaps_env_loc['location_domain'].present?
      base_whitelist << 'LOCATION_TIMEZONE' if @configmaps_env_loc['location_timezone'].present?
      applications.each_key do |app|
        base_whitelist << "TAG_#{app.underscore.upcase}"
      end
      base_whitelist
    end

    def update_param_value(param, applications, version, namespace)
      case param['name']
      when 'VERSION'
        param['value'] = version
      when 'NAMESPACE'
        param['value'] = namespace
      when 'APPLICATION_DOMAIN'
        param['value'] = ENV.fetch('LOCATION_DOMAIN', '')
      when 'LOCATION_DOMAIN', 'LOCATION_TIMEZONE'
        param['value'] = @configmaps_env_loc[param['name'].downcase]
      when 'REGISTRY_SERVER', 'REGISTRY_PROXY_SERVER', 'NAMESPACE_PREFIX'
        param['value'] = ENV[param['name']] if ENV[param['name']].present?
      else
        app_name = param['name'].split('_')[1..].join('-').downcase
        param['value'] = applications[app_name] if applications.key?(app_name)
      end
    end
  end
end
