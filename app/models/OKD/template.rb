# frozen_string_literal: true

module OKD
  class Template
    def self.deploy(service_name, version)
      namespace = "#{ENV.fetch('NAMESPACE_PREFIX', 'cloud')}-#{service_name}"
      OkdClient.create_namespace(service_name) unless OkdClient.namespaces.include?(namespace)
      github_template = Github::Template.with_updated_params(version, service_name, namespace)
      DNS.create_dns_records(github_template)
      generated_template = OkdClient.generate_service_template(github_template, service_name, namespace)
      generated_template['objects'].map do |object|
        object_name = object.dig('metadata', 'name')
        eval("OkdClient.create_#{object['kind'].underscore}(object, namespace, object_name)")
      end
    end
  end
end
