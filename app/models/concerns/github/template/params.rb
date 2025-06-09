# frozen_string_literal: true

module Github
  class Template
    module Params
      def template_with_updated_params(template, applications, version, namespace)
        white_list = %w[VERSION APPLICATION_DOMAIN NAMESPACE REGISTRY_SERVER REGISTRY_PROXY_SERVER
                        NAMESPACE_PREFIX]
        configmaps_env_loc = OkdClient.configmaps_env_loc(namespace)
        white_list << 'LOCATION_DOMAIN' unless configmaps_env_loc['location_domain'].nil?
        white_list << 'LOCATION_TIMEZONE' unless configmaps_env_loc['location_timezone'].nil?
        applications.keys.map { |app| white_list.append "TAG_#{app.underscore.upcase}" }
        template['parameters'].map do |param|
          next unless white_list.include?(param['name'])

          case param['name']
          when 'VERSION'
            param['value'] = version
          when 'NAMESPACE'
            param['value'] = namespace
          when 'APPLICATION_DOMAIN'
            param['value'] = ENV['LOCATION_DOMAIN'].to_s
          when 'LOCATION_DOMAIN'
            param['value'] = configmaps_env_loc['location_domain']
          when 'LOCATION_TIMEZONE'
            param['value'] = configmaps_env_loc['location_timezone']
          when 'REGISTRY_SERVER'
            param['value'] = ENV['REGISTRY_SERVER'] if ENV['REGISTRY_SERVER']
          when 'REGISTRY_PROXY_SERVER'
            param['value'] = ENV['REGISTRY_PROXY_SERVER'] if ENV['REGISTRY_PROXY_SERVER']
          when 'NAMESPACE_PREFIX'
            param['value'] = ENV['NAMESPACE_PREFIX'] if ENV['NAMESPACE_PREFIX']
          else
            param['value'] =
              applications[param['name'].split('_')[1..].join('-').downcase]
          end
        end
        template
      end
    end
  end
end
