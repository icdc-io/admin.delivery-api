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

  def self.find_replecation_controller(list, app_name, revision, namespace)
    replecation_controllers = list.find do |rc|
      rc.dig('metadata', 'namespace') == namespace && rc.dig('metadata', 'name') == "#{app_name}-#{revision}"
    end
    replecation_controllers.dig('metadata', 'annotations', 'openshift.io/deployment.phase')
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
    delete_image_stream(service_name, namespace)
    delete_route(service_name, namespace)
    delete_service(service_name, namespace)
    delete_deployment_config(service_name, namespace)
    delete_deployment(service_name, namespace)
    delete_stateful_set(service_name, namespace)
    delete_job(service_name, namespace)
    delete_cron_job(service_name, namespace)
    delete_service_account(service_name, namespace)
    delete_config_map(service_name, namespace)
    delete_pod(service_name, namespace)
    delete_replication_controller(service_name, namespace)
    delete_daemon_set(service_name, namespace)
    delete_replica_set(service_name, namespace)
    delete_horizontal_pod_auto_scaler(service_name, namespace)
    delete_pvc_data(service_name, namespace) if delete_pvc_data == 'true'
    delete_pvc_backup(service_name, namespace) if delete_pvc_backup == 'true'
  end

  def self.get_service_imagestream(service_name)
    get_resource("apis/image.openshift.io/v1/namespaces/#{namespace(service_name)}/imagestreams/#{service_name}")
  end

  def self.create_namespace(service_name)
    Rails.logger.debug { "create_namespace: #{service_name}" }
    url = 'apis/project.openshift.io/v1/projectrequests'
    body = OkdClient.namespace_body(service_name)
    post_resource(url, body)
  end

  def self.create_image_stream_tag(service, app_name, app_version, service_repository)
    service_name = service.name
    Rails.logger.debug { "create_image_stream_tag: #{app_name}, #{service_name}, #{app_version}" }
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
    Rails.logger.debug { "create_image_stream_service_tag: #{params}" }
    url = "apis/image.openshift.io/v1/namespaces/#{namespace}/imagestreamtags"
    body = OkdClient.service_image_stream_tag_body(params)
    post_resource(url, body)
  end

  def self.generate_service_template(template, service_name, namespace)
    Rails.logger.debug { "generate_service_template: #{service_name}, #{template}" }
    url = "apis/template.openshift.io/v1/namespaces/#{namespace}/processedtemplates"
    body = template.to_json
    post_resource(url, body)
  end

  def self.create_service(body, namespace, name = nil)
    Rails.logger.debug { "create_service: #{namespace}" }
    resource = "api/v1/namespaces/#{namespace}/services"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def self.create_deployment_config(body, namespace, name = nil)
    Rails.logger.debug { "create_deployment_config: #{namespace}" }
    resource = "apis/apps.openshift.io/v1/namespaces/#{namespace}/deploymentconfigs"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def self.create_deployment(body, namespace, name = nil)
    Rails.logger.debug { "create_deployment: #{namespace}" }
    resource = "/apis/apps/v1/namespaces/#{namespace}/deployments"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def self.create_route(body, namespace, name = nil)
    Rails.logger.debug { "create_route: #{namespace}" }
    resource = "apis/route.openshift.io/v1/namespaces/#{namespace}/routes"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def self.create_secret(body, namespace, _name = nil)
    Rails.logger.debug { "create_secret: #{namespace}" }
    resource = "api/v1/namespaces/#{namespace}/secrets"
    post_resource(resource, body.to_json)
  end

  def self.create_service_account(body, namespace, _name = nil)
    Rails.logger.debug { "create_service_account: #{namespace}" }
    resource = "api/v1/namespaces/#{namespace}/serviceaccounts"
    post_resource(resource, body.to_json)
  end

  def self.create_config_map(body, namespace, name = nil)
    Rails.logger.debug { "create_config_map: #{namespace} " }
    resource = "api/v1/namespaces/#{namespace}/configmaps"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def self.create_persistent_volume_claim(body, namespace, name = nil)
    Rails.logger.debug { "create_persistent_volume_claim: #{namespace}" }
    resource = "api/v1/namespaces/#{namespace}/persistentvolumeclaims"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def self.create_image_stream(body, namespace, name = nil)
    Rails.logger.debug { "create_image_stream: #{namespace}" }
    resource = "apis/image.openshift.io/v1/namespaces/#{namespace}/imagestreams"
    body = body.to_json
    post_resource(resource, body) unless object_exists?("#{resource}/#{name}")
  end

  def self.create_role(body, namespace, _name = nil)
    Rails.logger.debug { "create_role: #{namespace}" }
    resource = "apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/roles"
    post_resource(resource, body.to_json)
  end

  def self.create_role_binding(body, namespace, _name = nil)
    Rails.logger.debug { "create_role_binding: #{namespace}" }
    resource = "apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings"
    post_resource(resource, body.to_json)
  end

  def self.create_cron_job(body, namespace, name = nil)
    Rails.logger.debug { "create_cron_job: #{namespace}" }
    resource = "apis/batch/v1/namespaces/#{namespace}/cronjobs"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def create_job(body, namespace, name = nil)
    Rails.logger.debug { "create_job: #{service_name}" }
    resource = "apis/batch/v1/namespaces/#{namespace}/jobs"
    body = body.to_json
    if object_exists?("#{resource}/#{name}")
      patch_resource("#{resource}/#{name}", body)
    else
      post_resource(resource, body)
    end
  end

  def self.delete_image_stream(service_name, namespace)
    resource = "apis/image.openshift.io/v1/namespaces/#{namespace}/imagestreams"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_route(service_name, namespace)
    resource = "apis/route.openshift.io/v1/namespaces/#{namespace}/routes"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_service(service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/services"
    options = "labelSelector=service=#{service_name}"
    service_names = get_resource(resource, options)['items'].map { |service| service.dig('metadata', 'name') }
    service_names.each do |name|
      delete_resource("#{resource}/#{name}")
    end
  end

  def self.delete_deployment_config(service_name, namespace)
    resource = "apis/apps.openshift.io/v1/namespaces/#{namespace}/deploymentconfigs"
    options = "labelSelector=service=#{service_name}"
    deploymentconfig_names = get_resource(resource, options)['items'].map { |dc| dc.dig('metadata', 'name') }
    deploymentconfig_names.each do |name|
      delete_resource("#{resource}/#{name}")
    end
  end

  def self.delete_deployment(service_name, namespace)
    resource = "apis/apps/v1/namespaces/#{namespace}/deployments"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_stateful_set(service_name, namespace)
    resource = "apis/apps/v1/namespaces/#{namespace}/statefulsets"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_job(service_name, namespace)
    resource = "apis/batch/v1/namespaces/#{namespace}/jobs"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_cron_job(service_name, namespace)
    resource = "apis/batch/v1/namespaces/#{namespace}/cronjobs"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_service_account(service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/serviceaccounts"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_config_map(service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/configmaps"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_pod(service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/pods"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_replication_controller(service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/replicationcontrollers"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_daemon_set(service_name, namespace)
    resource = "apis/apps/v1/namespaces/#{namespace}/daemonsets"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_replica_set(service_name, namespace)
    resource = "apis/apps/v1/namespaces/#{namespace}/replicasets"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_horizontal_pod_auto_scaler(service_name, namespace)
    resource = "apis/autoscaling/v1/namespaces/#{namespace}/horizontalpodautoscalers"
    options = "labelSelector=service=#{service_name}"
    delete_resource(resource, options)
  end

  def self.delete_pvc_data(service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/persistentvolumeclaims"
    options = "labelSelector=service=#{service_name},type=data"
    delete_resource(resource, options)
  end

  def self.delete_pvc_backup(service_name, namespace)
    resource = "api/v1/namespaces/#{namespace}/persistentvolumeclaims"
    options = "labelSelector=service=#{service_name},type=backup"
    delete_resource(resource, options)
  end

  def self.object_exists?(url)
    get_resource(url)[:code] != 404
  end
end
