# frozen_string_literal: true

class Service
  attr_accessor :image_stream, :name, :namespace, :release, :current_version, :downgrade_versions,
                :update_version, :upgrade_version

  def initialize(name, image_stream = nil)
    image_stream ||= OKD::ImageStream.get(name)
    return unless image_stream

    @name = image_stream.name
    @namespace = image_stream.namespace
    @release = image_stream.current_release_version
    @current_version = image_stream.current_version
    @downgrade_versions = image_stream.downgrade_versions
    @update_version = Changelog.last_update_version(name, current_version)
    @upgrade_version = Changelog.last_upgrade_version(name, release)
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

  def self.install(service_name, version)
    version = Changelog.find_version(service_name, version)
    Template.deploy(service_name, version)
    Service.find_by_name(service_name).update_service_version(version)
  end

  def update_service_version(version)
    service_repository = "#{GithubClient.registry_server(name)}/#{namespace}"
    version['applications'].compact.map do |app|
      app_name = app['name']
      app_version = app['tag']
      OkdClient.create_image_stream_tag(self, app_name, app_version, service_repository)
      image_stream_tag_name = "#{name}-#{app_name}"
      OkdClient.set_latest_tag_version(image_stream_tag_name, app_version, namespace)
    end
    OkdClient.create_image_stream_service_tag(name, version['version'], namespace)
    OkdClient.set_latest_tag_version(name, version['version'], namespace)
    OkdClient.rollout_deployment_config(name, namespace)
  end

  def delete(delete_pvc_data, delete_pvc_backup)
    OkdClient.delete_image_stream(name, namespace)
    OkdClient.delete_route(name, namespace)
    OkdClient.delete_service(name, namespace)
    OkdClient.delete_deployment_config(name, namespace)
    OkdClient.delete_deployment(name, namespace)
    OkdClient.delete_stateful_set(name, namespace)
    OkdClient.delete_job(name, namespace)
    OkdClient.delete_cron_job(name, namespace)
    OkdClient.delete_service_account(name, namespace)
    OkdClient.delete_config_map(name, namespace)
    OkdClient.delete_pod(name, namespace)
    OkdClient.delete_replication_controller(name, namespace)
    OkdClient.delete_daemon_set(name, namespace)
    OkdClient.delete_replica_set(name, namespace)
    OkdClient.delete_horizontal_pod_auto_scaler(name, namespace)
    OkdClient.delete_pvc_data(name, namespace) if delete_pvc_data == 'true'
    OkdClient.delete_pvc_backup(name, namespace) if delete_pvc_backup == 'true'
  end
end
