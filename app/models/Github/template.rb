# frozen_string_literal: true

module Github
  class Template
    extend Github::Template::Params
    # def self.download_url(service_name)
    #   GithubClient.get_resource("templates/#{service_name}.json")['download_url']
    # end

    def self.find_by_service_name(service_name)
      GithubClient.get_githubusercontent_resource("templates/#{service_name}.json")
    end

    def self.with_updated_params(version, service_name, namespace)
      template = find_by_service_name(service_name)
      applications = {}
      version['applications'].map { |app| applications[app['name']] = app['tag'] }
      template = template_with_updated_params(template, applications, version['version'], namespace)
    end
  end
end
