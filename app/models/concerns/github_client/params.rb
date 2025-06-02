# frozen_string_literal: true

class GithubClient
  module Params
    def self.template_with_updated_params(template, applications, _service, version, namespace)
      white_list = %w[VERSION APPLICATION_DOMAIN NAMESPACE REGISTRY_SERVER REGISTRY_PROXY_SERVER
                      NAMESPACE_PREFIX]
      configmaps_env_loc = OkdClient.configmaps_env_loc(namespace)
      white_list << 'LOCATION_DOMAIN' unless configmaps_env_loc['location_domain'].nil?
      white_list << 'LOCATION_TIMEZONE' unless configmaps_env_loc['location_timezone'].nil?
      applications.keys.map { |a| white_list.append "TAG_#{a.underscore.upcase}" }
      template['parameters'].map do |param|
        next unless white_list.include?(param['name'])

        param['value'] = case param['name']
                         when 'VERSION'
                           version
                         when 'NAMESPACE'
                           namespace
                         when 'APPLICATION_DOMAIN'
                           ENV.fetch('LOCATION_DOMAIN', '')
                         when 'LOCATION_DOMAIN'
                           configmaps_env_loc['location_domain']
                         when 'LOCATION_TIMEZONE'
                           configmaps_env_loc['location_timezone']
                         when 'REGISTRY_SERVER'
                           ENV.fetch('REGISTRY_SERVER', nil)
                         when 'REGISTRY_PROXY_SERVER'
                           ENV.fetch('REGISTRY_PROXY_SERVER', nil)
                         when 'NAMESPACE_PREFIX'
                           ENV.fetch('NAMESPACE_PREFIX', nil)
                         else
                           applications[param['name'].split('_')[1..].join('-').downcase]
                         end
      end
      template
    end
  end

  def dns_template_params(dns_param)
    case dns_param
    when /HOSTNAME_SYS_*/
      ENV.fetch('DNS_HOST_SYS', "sys.cloudgw-account.#{ENV['LOCATION_DOMAIN']}")
    when /HOSTNAME_INT_*/
      ENV.fetch('DNS_HOST_INT', "gwint.sys.ocp.#{ENV['LOCATION_DOMAIN']}")
    when /HOSTNAME_EXT_*/
      ENV.fetch('DNS_HOST_EXT', "gwext.sys.ocp.#{ENV['LOCATION_DOMAIN']}")
    when /HOSTNAME_VPN_*/
      ENV.fetch('DNS_HOST_VPN', "gwvpn.sys.ocp.#{ENV['LOCATION_DOMAIN']}")
    end
  end
end
