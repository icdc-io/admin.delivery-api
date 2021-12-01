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
    installed_service_version(data)[0..2]#  cut -d. -f-2
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
    post_request_api_os("apis/image.openshift.io/v1/namespaces/test/processedtemplates", template.to_json)
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
end

