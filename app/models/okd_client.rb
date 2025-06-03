# frozen_string_literal: true

include Authenticator
class OkdClient
  extend OkdClient::RequestBody
  # attr_accessor :service_name, :template

  # def initialize(service_name)
  #   @service_name = service_name
  #   template ||= Github::Template.find_by_service_name(service_name)
  # end

  def self.namespaces(prefix = nil)
    namespaces = get_resource('api/v1/namespaces')['items'].map { |namespace| namespace.dig('metadata', 'name') }
    namespaces = namespaces.select { |ns| ns.start_with?(prefix) } if prefix
    namespaces
  end

  def self.configmaps_env_loc(namespace)
    get_request_api_os("api/v1/namespaces/#{namespace}/configmaps/env-loc")['data']
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

  def self.update_image_stream_tag(name, version, namespace)
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

  def self.get_resource(resource, options = nil)
    os_creds = service_creds('os_api')
    url = os_creds['url']
    response = RestClient::Request.execute(
      method: :get,
      url: "#{url}/#{resource}?#{options}",
      headers: {
        Authorization: "Bearer #{os_creds['token']}"
      },
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)
  end

  def self.post_resource(resource, body)
    os_creds = service_creds('os_api')
    url = "#{os_creds['url']}/#{resource}"
    response = RestClient::Request.execute(
      method: :post,
      url: url,
      payload: body,
      headers: {
        content_type: 'application/json',
        Authorization: "Bearer #{os_creds['token']}",
        Accept: 'application/json'
      },
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)
    # Net::HTTP request
      # url = "#{url}/#{resource}"
      # uri = URI.parse(url)
      # request = Net::HTTP::Post.new(uri)
      # request.content_type = "application/json"
      # request["Authorization"] = "Bearer #{os_creds["token"]}"
      # request["Accept"] = "application/json"
      # request.body = body
      # response = Net::HTTP.start(uri.hostname, uri.port, req_options(uri)) do |http|
      #   http.request(request)
      # end
  rescue StandardError => e
    Rails.logger.info { "POST #{url} request failed: #{e}" }
  end

  def self.put_resource(resource, body)
    os_creds = service_creds('os_api')
    url = os_creds['url']
    response = RestClient::Request.execute(
      method: :put,
      url: "#{url}/#{resource}",
      payload: body,
      headers: {
        content_type: 'application/json',
        Authorization: "Bearer #{os_creds['token']}",
        Accept: 'application/json'
      },
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)
  end
end
