module OsHelper
  include RequestHelper

  def login
    os_creds = service_creds("os_api")
    system("oc login #{os_creds['url']} --token=#{os_creds['token']} --insecure-skip-tls-verify")
  end

  def installed_service_version(data)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/test/imagestreams/#{data["name"]}")["spec"]["tags"].select{ |d| d["name"] == "latest"}.first["from"]["name"]
  end

  def installed_release_version(data)
    installed_service_version(data)[0..2]
  end

  def all_installed_version(data)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/test/imagestreams/#{data["name"]}")["spec"]["tags"].select { |d| d["from"]["kind"] == "DockerImage" }.collect { |streams| streams["name"] }
  end

  def set_image_tag(data, version)
    put_request_api_os("apis/image.openshift.io/v1/namespaces/test/imagestreamtags/#{data["name"]}:latest", set_latest_image_stream_tag(data["name"], version))["tag"]["from"]["name"]
  end

  def create_image_stream_tag(name, version, repository)
    put_request_api_os("apis/image.openshift.io/v1/namespaces/test/imagestreamtags", image_stream_tag_body(name, version, repository))
  end

  def generate_service_template(template)
    post_request_api_os("apis/template.openshift.io/v1/namespaces/test/processedtemplates", template.to_json)
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

  def create_service(source)
    post_request_api_os("api/v1/namespaces/test/services", source["objects"].select { |s| s["kind"].eql?("Service") }.first.to_json)
  end

  def create_deployment_config(source)
    post_request_api_os("/apis/apps.openshift.io/v1/namespaces/test/deploymentconfigs", source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first.to_json))
  end

  def create_deployment(source)
    post_request_api_os("/apis/apps/v1/namespaces/test/deployments", source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first.to_json))
  end

  def create_route(source)
    post_request_api_os("/apis/route.openshift.io/v1/namespaces/test/routes", source["objects"].select { |s| s["kind"].eql?("Route") }.first.to_json))
  end

  def create_secret(source)
    post_request_api_os("api/v1/namespaces/test/secrets", source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first.to_json))
  end

  def create_service_account(source)
    post_request_api_os("api/v1/namespaces/test/serviceaccounts", source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first.to_json))
  end

  def create_configmap(source)
    post_request_api_os("api/v1/namespaces/test/configmaps", source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first.to_json))
  end

  def create_pvc(source)
    post_request_api_os("api/v1/namespaces/test/persistentvolumeclaims", source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first.to_json))
  end
  
  private
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

=begin

  def create_service_body
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "annotations": {
          "description": "#{desc}",
          "openshift.io/generated-by": "OpenShiftNewApp"
        },
        "creationTimestamp": nil,
        "labels": {
          "app": "#{name}",
          "template": "#{name}"
        },
        "name": "#{name}",
      "spec": {
        "selector":
          "name": "#{name}"
      }
    }.to_json
  end

  def create_deployment_config_body
    {
      "apiVersion": "v1",
      "kind": "DeploymentConfig"
    }.to_json
  end

  def create_deployment_body
    {
      "apiVersion": "v1",
      "kind": "Deployment"
    }.to_json
  end

  def create_route_body
    {
      "apiVersion": "v1",
      "kind": "Route"
    }.to_json
  end

  def create_secret_body
    {
      "apiVersion": "v1",
      "kind": "Secret",
      "metadata": {
        "name": "#{name}-secrets"
      }
    }.to_json
  end

  def create_service_account_body
    {
      "apiVersion": "v1",
      "kind": "ServiceAccount",
      "metadata":{
        "creationTimestamp": nil,
        "name": "#{account_name}" # <--- ask Danat
      }
    }.to_json
  end

  def create_configmap_body
    {
      "kind": "ConfigMap",
      "metadata": {
        "annotations": {
          "openshift.io/generated-by": "OpenShiftNewApp"
        },
        "creationTimestamp": nil,
        "labels": {
          "app": "#{name}",
          "template": "#{name}"
        },
        "name": "#{name}-config"
       }
    }.to_json
  end

  def create_pvc_body
    {
      "kind": "PersistentVolumeClaim"
    }.to_json
  end
=end
end

