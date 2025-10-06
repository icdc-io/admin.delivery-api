# frozen_string_literal: true

class Template
  extend Template::Params

  def self.find_by(service_name:)
    GithubClient.get_githubusercontent_resource("templates/#{service_name}.json")
  end

  def self.with_updated_params(version, service_name, namespace)
    template = find_by(service_name:)
    applications = {}
    version['applications'].map { |app| applications[app['name']] = app['tag'] }
    template_with_updated_params(template, applications, version['version'], namespace)
  end

  def self.deploy(service_name, version)
    namespace = "#{ENV.fetch('NAMESPACE_PREFIX', 'cloud')}-#{service_name}"
    OkdClient.create_namespace(service_name) unless OkdClient.namespaces.include?(namespace)
    github_template = Template.with_updated_params(version, service_name, namespace)
    DNS.create_records(github_template)
    generated_template = OkdClient.generate_service_template(github_template, service_name, namespace)
    generated_template['objects'].map do |body|
      object_name = body.dig('metadata', 'name')
      OkdClient.create_object_from_template(body['kind'], body, namespace, object_name)
    end
  end
end
