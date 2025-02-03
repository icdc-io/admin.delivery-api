module OsCreateHelper
  include OsCommonHelper
  #include OsHelper

  def create_image_stream_tag(app_name, version, repository, service_name)
    Rails.logger.debug { "create_image_stream_tag: #{app_name}, #{service_name}, #{version}" }
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreamtags", image_stream_tag_body(app_name, version, repository, service_name)) #uncomment
  end

  def object_exists?(url)
    get_request_api_os(url) != "404"
  end

  def create_image_stream_import(app_name, version, repository, service_name)
    Rails.logger.debug { "create_image_stream_import: #{app_name}, #{service_name}, #{version}" }
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreamimports", image_stream_import_body(app_name, version, repository, service_name))
  end

  def create_image_stream_service_tag(service)
    Rails.logger.debug { "create_image_stream_service_tag: #{service}" }
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service["NAME"])}/imagestreamtags", image_stream_service_tag_body(service)) #uncomment
  end

  def generate_service_template(template, service_name)
    Rails.logger.debug { "generate_service_template: #{service_name}, #{template}" }
    post_request_api_os("apis/template.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/processedtemplates", template.to_json)
  end

  def create_service(source, service_name, name = nil)
    Rails.logger.debug { "create_service: #{service_name}"}
    unless object_exists?("api/v1/namespaces/#{get_os_namespace(service_name)}/services/#{name}")
      post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/services", source.to_json)# if body
    else
      post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/services/#{name}", source.to_json)# if body
    end
  end

  def create_deployment_config(source, service_name, name = nil)
    Rails.logger.debug { "create_deployment_config: #{service_name}"}
    unless object_exists?("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs/#{name}")
      post_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs", source.to_json)# if body
    else
      patch_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs/#{name}", source.to_json)
    end
  end

  def create_deployment(source, service_name, name = nil)
    Rails.logger.debug { "create_deployment: #{service_name}" }
    unless object_exists?("/apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/deployments/#{name}")
      post_request_api_os("/apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/deployments", source.to_json)# if body
    else
      patch_request_api_os("/apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/deployments/#{name}", source.to_json)# if body
    end
  end

  def create_route(source, service_name, name = nil)
    Rails.logger.debug { "create_route: #{service_name}" }
    unless object_exists?("apis/route.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/routes/#{name}")
      post_request_api_os("apis/route.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/routes", source.to_json)# if body
    else
      patch_request_api_os("apis/route.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/routes/#{name}", source.to_json)# if body
    end
  end

  def create_secret(source, service_name, name = nil)
    Rails.logger.debug { "create_secret: #{service_name}"}
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/secrets", source.to_json)# if body
  end

  def create_service_account(source, service_name, name = nil)
    Rails.logger.debug { "create_service_account: #{service_name}" }
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/serviceaccounts", source.to_json)# if body
  end

  def create_config_map(source, service_name, name = nil)
    Rails.logger.debug { "create_config_map: #{service_name} "}
    unless object_exists?("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps/#{name}")
      post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps", source.to_json)# if body
    else
      patch_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps/#{name}", source.to_json)# if body
    end
  end

  def create_persistent_volume_claim(source, service_name, name = nil)
    Rails.logger.debug { "create_persistent_volume_claim: #{service_name}" }
    unless object_exists?("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims/#{name}")
      post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims", source.to_json)# if body
    else
      patch_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims/#{name}", source.to_json)
    end
  end

  def create_namespace(service_name)
    Rails.logger.debug { "create_namespace: #{service_name}" }
    post_request_api_os("apis/project.openshift.io/v1/projectrequests", create_namespace_body(service_name))
  end

  def create_image_stream(source, service_name, name = nil)
    Rails.logger.debug { "create_image_stream: #{service_name}" }
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams", source.to_json)
  end

  def create_role(source, service_name, name = nil)
    Rails.logger.debug { "create_role: #{service_name}" }
    post_request_api_os("apis/rbac.authorization.k8s.io/v1/namespaces/#{get_os_namespace(service_name)}/roles", source.to_json)
  end

  def create_role_binding(source, service_name, name = nil)
    Rails.logger.debug { "create_role_binding: #{service_name}" }
    post_request_api_os("apis/rbac.authorization.k8s.io/v1/namespaces/#{get_os_namespace(service_name)}/rolebindings", source.to_json)
  end

  def create_cron_job(source, service_name, name = nil)
    Rails.logger.debug { "create_cron_job: #{service_name}" }
    unless object_exists?("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/cronjobs/#{name}")
      post_request_api_os("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/cronjobs", source.to_json)
    else
      patch_request_api_os("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/cronjobs/#{name}", source.to_json)
    end
  end

  def create_job(source, service_name, name = nil)
    Rails.logger.debug { "create_job: #{service_name}" }
    unless object_exists?("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/jobs/#{name}")
      post_request_api_os("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/jobs", source.to_json)
    else
      patch_request_api_os("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/jobs/#{name}", source.to_json)
    end
  end

  def create_stateful_set(source, service_name, name = nil)
    Rails.logger.debug { "create_stateful_set: #{service_name}" }
    unless object_exists?("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/statefulsets/#{name}")
      post_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/statefulsets", source.to_json)
    else
      patch_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/statefulsets/#{name}", source.to_json)
    end
  end

  def create_daemon_set(source, service_name, name = nil)
    Rails.logger.debug { "create_daemon_set: #{service_name}" }
    unless object_exists?("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/daemonsets/#{name}")
      post_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/daemonsets", source.to_json)
    else
      patch_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/daemonsets/#{name}", source.to_json)
    end
  end

  def create_horizontal_pod_autoscaler(source, service_name, name = nil)
    Rails.logger.debug { "create_horizontal_pod_autoscaler: #{service_name}" }
    unless object_exists?("apis/autoscaling/v2/namespaces/#{get_os_namespace(service_name)}/horizontalpodautoscalers/#{name}")
      post_request_api_os("apis/autoscaling/v2/namespaces/#{get_os_namespace(service_name)}/horizontalpodautoscalers", source.to_json)
    else
      patch_request_api_os("apis/autoscaling/v2/namespaces/#{get_os_namespace(service_name)}/horizontalpodautoscalers/#{name}", source.to_json)
    end
  end

  private

  def create_namespace_body(service_name)
    prefix = ENV['NAMESPACE_PREFIX'] || 'cloud'
    {
      "apiVersion": "project.openshift.io/v1",
      "kind": "ProjectRequest",
      "metadata": {
        "name": "#{prefix}-#{service_name}"
      },
      "displayName": "#{service_name.capitalize} Service"
   }.to_json
  end

end
