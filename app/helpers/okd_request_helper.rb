# frozen_string_literal: true

module OkdRequestHelper
  include Authenticator

  def get_resource(resource, options = nil)
    os_creds = service_creds('os_api')
    url = "#{os_creds['url']}/#{resource}?#{options}"
    response = RestClient::Request.execute(
      method: :get,
      url: url,
      headers: {
        Authorization: "Bearer #{os_creds['token']}"
      },
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)
  rescue RestClient::NotFound => e
    Rails.logger.error { "GET #{url} request failed (#{e.response.code} status): #{JSON.parse(e.response.body)['message']}" }
    { message: e.message, code: 404 }
  rescue RestClient::Exception => e
    Rails.logger.error { "GET #{url} request failed (#{e.response.code} status): #{JSON.parse(e.response.body)['message']}" }
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
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)
  rescue RestClient::Exception => e
    Rails.logger.error { "POST #{url} request failed (#{e.response.code} status): #{JSON.parse(e.response.body)['message']}" }
  end

  def put_resource(resource, body)
    os_creds = service_creds('os_api')
    url = "#{os_creds['url']}/#{resource}"
    response = RestClient::Request.execute(
      method: :put,
      url: url,
      payload: body,
      headers: {
        content_type: 'application/json',
        Authorization: "Bearer #{os_creds['token']}",
        Accept: 'application/json'
      },
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)
  rescue RestClient::Exception => e
    Rails.logger.error { "PUT #{url} request failed (#{e.response.code} status): #{JSON.parse(e.response.body)['message']}" }
  end

  def delete_resource(resource, options = nil)
    os_creds = service_creds('os_api')
    url = "#{os_creds['url']}/#{resource}?#{options}"
    response = RestClient::Request.execute(
      method: :delete,
      url: url,
      headers: {
        Authorization: "Bearer #{os_creds['token']}"
      },
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)
  rescue RestClient::Exception => e
    Rails.logger.error { "DELETE #{url} request failed (#{e.response.code} status): #{JSON.parse(e.response.body)['message']}" }
  end

  def patch_resource(resource, body)
    os_creds = service_creds('os_api')
    url = "#{os_creds['url']}/#{resource}"
    response = RestClient::Request.execute(
      method: :patch,
      url: url,
      payload: body,
      headers: {
        content_type: 'application/merge-patch+json',
        Authorization: "Bearer #{os_creds['token']}",
        Accept: 'application/json'
      },
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)
  rescue RestClient::Exception => e
    Rails.logger.error { "PATCH #{url} request failed (#{e.response.code} status): #{JSON.parse(e.response.body)['message']}" }
  end
end
