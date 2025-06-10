# frozen_string_literal: true

module OkdRequestHelper
  include Authenticator

  def get_resource(resource, options = nil)
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
  rescue RestClient::NotFound => e
    { message: e.message, code: 404 }
  end

  def post_resource(resource, body)
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
  rescue StandardError => e
    Rails.logger.error { "POST #{url} request failed: #{e.message}" }
  end

  def put_resource(resource, body)
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

  def delete_resource(resource, options = nil)
    os_creds = service_creds('os_api')
    url = os_creds['url']
    response = RestClient::Request.execute(
      method: :delete,
      url: "#{url}/#{resource}?#{options}",
      headers: {
        Authorization: "Bearer #{os_creds['token']}"
      },
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error { "DELETE #{url} request failed: #{e.message}" }
  end

  def patch_resource(resource, body)
    os_creds = service_creds('os_api')
    url = os_creds['url']
    response = RestClient::Request.execute(
      method: :patch,
      url: "#{url}/#{resource}",
      payload: body,
      headers: {
        content_type: 'application/merge-patch+json',
        Authorization: "Bearer #{os_creds['token']}",
        Accept: 'application/json'
      },
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)
  end
end
