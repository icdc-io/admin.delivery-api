# frozen_string_literal: true

class Service
  attr_accessor :image_stream, :name, :namespace, :current_version, :downgrade_versions, :update_version,
                :upgrade_version

  def initialize(name, image_stream = nil)
    image_stream ||= OKD::ImageStream.get(name)
    return unless image_stream

    @name = image_stream.name
    @namespace = image_stream.namespace
    @current_version = image_stream.current_version
    @downgrade_versions = image_stream.downgrade_versions
    @update_version = Github::Changelog.last_update_version(name, image_stream.current_version)
    @upgrade_version = Github::Changelog.last_upgrade_version(name, image_stream.current_release_version)
  end

  def self.all
    OKD::ImageStream.all.map do |image_stream|
      next unless image_stream

      new(image_stream.name, image_stream)
    end
  end

  def self.find_by_name(name)
    service = new(name)
    return if service.instance_variables.empty?

    service
  end

  def update_service_version(version)
    service_repository = "#{GithubClient.registry_server(name)}/#{namespace}"
    version['applications'].compact.map do |app|
      app_name = app['name']
      app_version = app['tag']
      OkdClient.create_image_stream_tag(self, app_name, app_version, service_repository)
      image_stream_tag_name = "#{name}-#{app_name}"
      OkdClient.update_image_stream_tag(image_stream_tag_name, app_version, namespace)
    end
    OkdClient.create_image_stream_service_tag(name, version['version'], namespace)
    OkdClient.update_image_stream_tag(name, version['version'], namespace)
  end
end
