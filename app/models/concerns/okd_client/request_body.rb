# frozen_string_literal: true

class OkdClient
  module RequestBody
    def latest_image_stream_tag_body(name, version)
      {
        "kind": 'ImageStreamTag',
        "apiVersion": 'image.openshift.io/v1',
        "metadata": {
          "name": "#{name}:latest"
        },
        "tag": {
          "name": 'latest',
          "annotations": nil,
          "from": {
            "kind": 'ImageStreamTag',
            "name": version.to_s
          },
          "importPolicy": {},
          "referencePolicy": {
            "type": 'Local'
          }
        },
        "lookupPolicy": {
          "local": false
        }
      }.to_json
    end

    def image_stream_tag_body(app_name, version, repository, service_name)
      {
        "kind": 'ImageStreamTag',
        "apiVersion": 'image.openshift.io/v1',
        "metadata": {
          "name": "#{service_name}-#{app_name}:#{version}"
        },
        "tag": {
          "name": '',
          "annotations": {},
          "from": {
            "kind": 'DockerImage',
            "name": "#{repository}/#{app_name}:#{version}"
          },
          "importPolicy": {},
          "referencePolicy": {
            "type": 'Local'
          }
        },
        "lookupPolicy": {
          "local": false
        }
      }.to_json
    end

    def image_stream_import_body(app_name, version, repository, service_name)
      {
        "kind": 'ImageStreamImport',
        "apiVersion": 'image.openshift.io/v1',
        "metadata": {
          "name": "#{service_name}-#{app_name}"
        },
        "spec": {
          "import": true,
          "images": [
            {
              "from": {
                "kind": 'DockerImage',
                "name": "#{repository}/#{app_name}:#{version}"
              },
              "to": {
                "name": version.to_s
              },
              "importPolicy": {
                "insecure": true,
                "importMode": 'Legacy'
              },
              "referencePolicy": {
                "type": 'Source'
              }
            }
          ]
        }
      }.to_json
    end

    def service_image_stream_tag_body(body)
      {
        "kind": 'ImageStreamTag',
        "apiVersion": 'image.openshift.io/v1',
        "metadata": {
          "name": "#{body['NAME']}:#{body['VERSION']}"
        },
        "tag": {
          "name": '',
          "annotations": {},
          "importPolicy": {},
          "referencePolicy": {
            "type": 'Source'
          }
        },
        "lookupPolicy": {
          "local": false
        }
      }.to_json
    end

    def namespace_body(service_name)
      prefix = ENV['NAMESPACE_PREFIX'] || 'cloud'
      {
        "apiVersion": 'project.openshift.io/v1',
        "kind": 'ProjectRequest',
        "metadata": {
          "name": "#{prefix}-#{service_name}"
        },
        "displayName": "#{service_name.capitalize} Service"
      }.to_json
    end

    def rollout_dc_template(deploymentconfig_name)
      {
        "kind": 'DeploymentRequest',
        "apiVersion": 'apps.openshift.io/v1',
        "name": deploymentconfig_name.to_s,
        "latest": true,
        "force": true
      }.to_json
    end
  end
end
