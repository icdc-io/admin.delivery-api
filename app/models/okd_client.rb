# frozen_string_literal: true

include Authenticator
include OkdRequestHelper
class OkdClient
  extend OkdClient::RequestBody

  def self.namespaces(prefix = nil)
    namespaces = get_resource('api/v1/namespaces')['items'].map { |namespace| namespace.dig('metadata', 'name') }
    namespaces = namespaces.select { |ns| ns.start_with?(prefix) } if prefix
    namespaces
  end

  def self.namespace(service_name)
    ENV.fetch('NAMESPACE_PREFIX', 'cloud') + '-' + service_name
  end

  def self.select_service_dcs(list, namespace, service_name)
    list.select do |dc|
      dc.dig('metadata', 'namespace') == namespace && dc.dig('metadata', 'labels', 'service') == service_name
    end
  end

  def self.find_replication_controller(list, app_name, revision, namespace)
    replication_controllers = list.find do |rc|
      rc.dig('metadata', 'namespace') == namespace && rc.dig('metadata', 'name') == "#{app_name}-#{revision}"
    end
    replication_controllers.dig('metadata', 'annotations', 'openshift.io/deployment.phase')
  end

  def self.select_service_pvc(list, namespace, service_name)
    list.select do |pvc|
      pvc.dig('metadata', 'namespace') == namespace && pvc.dig('metadata', 'labels', 'service') == service_name
    end
  end

  def self.select_service_pvc_by_type(list, namespace, service_name, type)
    list.select do |pvc|
      pvc.dig('metadata', 'namespace') == namespace && pvc.dig('metadata', 'labels', 'service') == service_name &&
        pvc.dig('metadata', 'labels', 'type') == type
    end
  end

  def self.configmaps_env_loc(namespace)
    get_resource("api/v1/namespaces/#{namespace}/configmaps/env-loc")['data']
  end

  def self.delete_service_objects(service_name, namespace, delete_pvc_data, delete_pvc_backup)
    %w[ImageStream Route Deployment StatefulSet Job CronJob ServiceAccount ConfigMap Pod
       ReplicationController DaemonSet ReplicaSet HorizontalPodAutoscaler  ].map do |object_name|
      delete_object(object_name, service_name, namespace)
    end
    %w[Service DeploymentConfig].map do |object_name|
      delete_objects(object_name, service_name, namespace)
    end
    delete_pvc_object('data', service_name, namespace) if delete_pvc_data == 'true'
    delete_pvc_object('backup', service_name, namespace) if delete_pvc_backup == 'true'
  end

  def self.get_service_imagestream(service_name)
    get_resource("apis/image.openshift.io/v1/namespaces/#{namespace(service_name)}/imagestreams/#{service_name}")
  end

  def self.create_namespace(service_name)
    Rails.logger.info { "create_namespace: #{service_name}" }
    url = 'apis/project.openshift.io/v1/projectrequests'
    body = OkdClient.namespace_body(service_name)
    post_resource(url, body)
  end

  def self.create_image_stream_tag(service, app_name, app_version, service_repository)
    service_name = service.name
    Rails.logger.info { "create_image_stream_tag: #{app_name}, #{service_name}, #{app_version}" }
    url = "apis/image.openshift.io/v1/namespaces/#{service.namespace}/imagestreamtags"
    body = OkdClient.image_stream_tag_body(app_name, app_version, service_repository, service_name)
    post_resource(url, body)
  end

  def self.set_latest_tag_version(name, version, namespace)
    url = "apis/image.openshift.io/v1/namespaces/#{namespace}/imagestreamtags/#{name}:latest"
    body = OkdClient.latest_image_stream_tag_body(name, version)
    put_resource(url, body).dig('tag', 'from', 'name')
  end

  def self.create_image_stream_service_tag(name, version, namespace)
    params = { 'NAME' => name, 'VERSION' => version }
    Rails.logger.info { "create_image_stream_service_tag: #{params}" }
    url = "apis/image.openshift.io/v1/namespaces/#{namespace}/imagestreamtags"
    body = OkdClient.service_image_stream_tag_body(params)
    post_resource(url, body)
  end

  def self.generate_service_template(template, service_name, namespace)
    Rails.logger.info { "generate_service_template: #{service_name}, #{template}" }
    url = "apis/template.openshift.io/v1/namespaces/#{namespace}/processedtemplates"
    body = template.to_json
    post_resource(url, body)
  end

  def self.create_object_from_template(type, body, namespace, app_name)
    Rails.logger.info { "create #{type}: #{namespace}" }
    api_groups = YAML.load_file('config/okd_api_groups.yml')
    api_group = api_groups[type]['api_group']
    endpoint = api_groups[type]['endpoint']
    resource = "#{api_group}/namespaces/#{namespace}/#{endpoint}"
    body = body
    return if object_exists?("#{resource}/#{app_name}")

    post_resource(resource, body.to_json)
  end

  def self.delete_object(object_name, service_name, namespace)
    Rails.logger.info { "delete #{object_name}: #{namespace}" }
    api_groups = YAML.load_file('config/okd_api_groups.yml')
    api_url = api_groups[object_name]['api_group']
    endpoint = api_groups[object_name]['endpoint']
    resource = "#{api_url}/namespaces/#{namespace}/#{endpoint}"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_objects(object_name, service_name, namespace)
    Rails.logger.info { "delete #{object_name}: #{namespace}" }
    api_groups = YAML.load_file('config/okd_api_groups.yml')
    api_url = api_groups[object_name]['api_group']
    endpoint = api_groups[object_name]['endpoint']
    resource = "#{api_url}/namespaces/#{namespace}/#{endpoint}"
    options = "labelSelector=service=#{service_name}"
    obj_names = get_resource(resource, options)['items'].map { |obj_name| obj_name.dig('metadata', 'name') }
    obj_names.each do |name|
      delete_resource("#{resource}/#{name}")
    end
  end

  def self.delete_pvc_object(type, service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/persistentvolumeclaims"
    options = "labelSelector=service=#{service_name},type=#{type}"
    delete_resource(resource, options)
  end

  def self.object_exists?(url, options = nil)
    get_resource(url, options)[:code] != 404
  end
end
