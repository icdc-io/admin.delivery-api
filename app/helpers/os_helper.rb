require 'json'

module OsHelper
  include RequestHelper

  def login
    os_creds = service_creds("os_api")
    system("oc login #{os_creds['url']} --token=#{os_creds['token']} --insecure-skip-tls-verify")
  end

  def installed_service_version(data)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{generate_namespace(data["name"])}/imagestreams/#{data["name"]}")["spec"]["tags"].select{ |d| d["name"] == "latest"}.first["from"]["name"]
  end

  def installed_release_version(data)
    installed_service_version(data)[0..2]
  end

  def all_installed_version(data)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{$NAMESPACE}/imagestreams/#{data["name"]}")["spec"]["tags"].select { |d| d["from"]["kind"] == "DockerImage" }.collect { |streams| streams["name"] }
  end

  def set_image_tag(data, version)
    put_request_api_os("apis/image.openshift.io/v1/namespaces/#{$NAMESPACE}/imagestreamtags/#{data["name"]}:latest", set_latest_image_stream_tag(data["name"], version)).dig('tag','from','name')
  end

  def create_image_stream_tag(name, version, repository)
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{$NAMESPACE}/imagestreamtags", image_stream_tag_body(name, version, repository))
  end

  def generate_service_template(template)
    post_request_api_os("apis/template.openshift.io/v1/namespaces/#{$NAMESPACE}/processedtemplates", template.to_json)
  end

  def get_deployment_config_revision(image_stream_name)
    get_request_api_os("apis/apps.openshift.io/v1/namespaces/#{$NAMESPACE}/deploymentconfigs/#{image_stream_name}").dig('status', 'latestVersion')
  end

  def get_replication_controller_status(image_stream_name, revision)
    get_request_api_os("api/v1/namespaces/#{$NAMESPACE}/replicationcontrollers/#{image_stream_name}-#{revision}").dig('metadata','annotations','openshift.io/deployment.phase')
  end

  def install_service(source)
    create_service(source)
    create_deployment_config(source)
    create_deployment(source)
    create_route(source)
    create_secret(source)
    create_service_account(source)
    create_configmap(source)
    create_pvc(source)
  end

  def delete_service(service_name, delete_persistent_data)
    delete_image_stream(service_name)
    delete_os_service(service_name)
    delete_deployment_config(service_name)
    delete_deployment(service_name)
    delete_route(service_name)
    delete_secret(service_name)
    delete_service_account(service_name)
    delete_config_map(service_name)
    delete_pvc(service_name) if delete_persistent_data
    delete_namespace if delete_persistent_data
  end

   def check_deleted_status(service_name, delete_persistent_data)
    return_codes = []
    return_codes << check_image_stream(service_name)
    return_codes << check_os_service(service_name)
    return_codes << check_deployment_config(service_name)
    return_codes << check_deployment(service_name)
    return_codes << check_route(service_name)
    return_codes << check_secret(service_name)
    return_codes << check_service_account(service_name)
    return_codes << check_config_map(service_name)
    return_codes << check_pvc(service_name) if delete_persistent_data
    return_codes << check_namespace if delete_persistent_data
    return true if return_codes.uniq.count > 1
    return true
  end

  def create_service(source)
    body = source["objects"].select { |s| s["kind"].eql?("Service") }.first
    post_request_api_os("api/v1/namespaces/#{$NAMESPACE}/services", body.to_json) if body
  end

  def create_deployment_config(source)
    body = source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first
    post_request_api_os("/apis/apps.openshift.io/v1/namespaces/#{$NAMESPACE}/deploymentconfigs", body.to_json) if body
  end

  def create_deployment(source)
    body = source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first
    post_request_api_os("/apis/apps/v1/namespaces/#{$NAMESPACE}/deployments", body.to_json) if body
  end

  def create_route(source)
    body = source["objects"].select { |s| s["kind"].eql?("Route") }.first
    post_request_api_os("/apis/route.openshift.io/v1/namespaces/#{$NAMESPACE}/routes", body.to_json) if body
  end

  def create_secret(source)
    body = source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first
    post_request_api_os("api/v1/namespaces/#{$NAMESPACE}/secrets", body.to_json) if body
  end

  def create_service_account(source)
    body = source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first
    post_request_api_os("api/v1/namespaces/#{$NAMESPACE}/serviceaccounts", body.to_json) if body
  end

  def create_configmap(source)
    body = source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first
    post_request_api_os("api/v1/namespaces/#{$NAMESPACE}/configmaps", body.to_json) if body
  end

  def create_pvc(source)
    body = source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first
    post_request_api_os("api/v1/namespaces/#{$NAMESPACE}/persistentvolumeclaims", body.to_json) if body
  end

  def create_namespace
    post_request_api_os("apis/project.openshift.io/v1/projects", create_namespace_body)
  end

  def delete_namespace
    delete_request_api_os("apis/project.openshift.io/v1/projects/#{$NAMESPACE}")
  end
 
  def delete_image_stream(service_name)
    delete_request_api_os("apis/image.openshift.io/v1/namespaces/#{$NAMESPACE}/imagestreams/#{service_name}")
  end

  def delete_os_service(service_name)
    delete_request_api_os("api/v1/namespaces/#{$NAMESPACE}/services/#{service_name}")
  end
 
  def delete_deployment_config(service_name)
    delete_request_api_os("apis/apps.openshift.io/v1/namespaces/#{$NAMESPACE}/deploymentconfigs/#{service_name}")
  end

  def delete_deployment(service_name)
    delete_request_api_os("apis/apps/v1/namespaces/#{$NAMESPACE}/deployments/#{service_name}")
  end

  def delete_route(service_name)
    delete_request_api_os("apis/route.openshift.io/v1/namespaces/#{$NAMESPACE}/routes/#{service_name}")
  end

  def delete_secret(service_name)
    delete_request_api_os("api/v1/namespaces/#{$NAMESPACE}/secrets/#{service_name}")
  end

  def delete_service_account(service_name)
    delete_request_api_os("api/v1/namespaces/#{$NAMESPACE}/serviceaccounts/#{service_name}")
  end

  def delete_config_map(service_name)
    delete_request_api_os("api/v1/namespaces/#{$NAMESPACE}/configmaps/#{service_name}")
  end

  def delete_pvc(service_name)
    delete_request_api_os("api/v1/namespaces/#{$NAMESPACE}/persistentvolumeclaims/#{service_name}")
  end

  def check_namespace
    get_request_api_os("apis/project.openshift.io/v1/projects/#{$NAMESPACE}")
  end

  def check_image_stream(service_name)
    is_name = image_stream_by_service(service_name).dig('metadata', 'name')
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{$NAMESPACE}/imagestreams/#{is_name}")
  end

  def check_os_service(service_name)
    get_request_api_os("api/v1/namespaces/#{$NAMESPACE}/services/#{service_name}")
  end

  def check_deployment_config(service_name)
    get_request_api_os("apis/apps.openshift.io/v1/namespaces/#{$NAMESPACE}/deploymentconfigs/#{service_name}")
  end

  def check_deployment(service_name)
    get_request_api_os("apis/apps/v1/namespaces/#{$NAMESPACE}/deployments/#{service_name}")
  end

  def check_route(service_name)
    get_request_api_os("apis/route.openshift.io/v1/namespaces/#{$NAMESPACE}/routes/#{service_name}")
  end

  def check_secret(service_name)
    get_request_api_os("api/v1/namespaces/#{$NAMESPACE}/secrets/#{service_name}")
  end

  def check_service_account(service_name)
    get_request_api_os("api/v1/namespaces/#{$NAMESPACE}/serviceaccounts/#{service_name}")
  end

  def check_config_map(service_name)
    get_request_api_os("api/v1/namespaces/#{$NAMESPACE}/configmaps/#{service_name}")
  end

  def check_pvc(service_name)
    get_request_api_os("api/v1/namespaces/#{$NAMESPACE}/persistentvolumeclaims/#{service_name}")
  end

  def get_location
    return ENV["LOCATION_NAME"] unless ENV["LOCATION_NAME"].nil?
    return service_creds('os_api')["url"].split(".")[-3]
  end

  private
  def generate_namespace(service_name)
    "icdc-#{service_name}"
  end

  def create_namespace_body
    {
      "apiVersion": "project.openshift.io/v1",
      "kind": "Project",
      "metadata": {
        "annotations": {
          "openshift.io/display-name": "#{$NAMESPACE}",
        },
        "name": "#{$NAMESPACE}"
      }
   }.to_json
  end


  def set_latest_image_stream_tag(name, version)
    {
      "kind": "ImageStreamTag",
      "apiVersion": "image.openshift.io/v1",
      "metadata": {
      "name": "#{name}:latest"
      },
      "tag": {
        "name": "latest",
        "annotations": nil,
        "from": {
          "kind": "ImageStreamTag",
          "name": "#{version}"
        },
        "importPolicy": {},
        "referencePolicy": {
          "type": "Source"
        }
      },
      "lookupPolicy": {
        "local": false
      }
    }.to_json
  end

  def image_stream_tag_body(name, version, repository)
    {
      "kind": "ImageStreamTag",
      "apiVersion": "image.openshift.io/v1",
      "metadata": {
        "name": "#{name}:#{version}"
      },
      "tag": {
        "name": "",
        "annotations": {},
        "from": {
          "kind": "DockerImage",
          "name": "#{repository}"
        },
      "importPolicy": {},
      "referencePolicy": {
        "type": "Local"
        }
      },
      "lookupPolicy": {
        "local": false
      }
    }.to_json
  end
end

