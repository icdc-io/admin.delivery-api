require 'net/http'
require 'uri'
require 'openssl'


module RequestHelper
  include Authenticator

  def request_api_github(resource, options = nil)
    url = service_creds('github_api')['url']
    url = "#{url}/#{resource}?#{options}"
    uri = URI.parse(url)
    get_request_api_github(uri)
  end

  def request_raw_github(resource, options = nil)
    url = service_creds('github')['url']
    url = "#{url}/#{resource}?#{options}"
    uri = URI.parse(url)

    get_request_api_github(uri)
  end

  def get_request_api_os(resource, options = nil)
    os_creds = service_creds('os_api')
    url = os_creds['url']
    url = "#{url}/#{resource}?#{options}"
    @uri = URI.parse(url)
    request = Net::HTTP::Get.new(@uri)
    request["Authorization"] = "Bearer #{os_creds['token']}"

    do_request(request)
  end

  def post_request_api_os(resource, body)
    os_creds = service_creds("os_api")
    url = os_creds["url"]
    url = "#{url}/#{resource}"
    @uri = URI.parse(url)

    request = Net::HTTP::Post.new(@uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{os_creds['token']}"
    request["Accept"] = "application/json"
    request.body = body

    do_request(request)
  end

  def put_request_api_os(resource, body)
    os_creds = service_creds("os_api")
    url = os_creds["url"]
    url = "#{url}/#{resource}"
    @uri = URI.parse(url)

    request = Net::HTTP::Put.new(@uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{os_creds['token']}"
    request["Accept"] = "application/json"
    request.body = body

    do_request(request)
  end

  def delete_request_api_os(resource)
    os_creds = service_creds("os_api")
    url = os_creds["url"]
    url = "#{url}/#{resource}"
    @uri = URI.parse(url)

    request = Net::HTTP::Delete.new(@uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{os_creds['token']}"
    request["Accept"] = "application/json"

    do_request(request)
  end 

  def get_request_api_github(uri)
    begin 
    response = Net::HTTP.get_response(uri)
    full_data = JSON.parse(response.body)
    rescue => err
    raise "#{response.body}__#{response.code} __#{uri}"
    end
#    raise "#{response.body}__#{response.code}"
    return full_data if response.code == '200'
    return response.code
  end

  def do_request(request)
    response = Net::HTTP.start(@uri.hostname, @uri.port, req_options) do |http|
      http.request(request)
    end

    data = JSON.parse(response.body)
    return data if response.code == '200'
    return data#response.code
  end

  def req_options
    {
      use_ssl: @uri.scheme == "https",
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }
  end
end
