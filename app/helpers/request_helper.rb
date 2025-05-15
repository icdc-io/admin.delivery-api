require 'net/http'
require 'uri'
require 'openssl'

module RequestHelper
  include Authenticator

  def request_github(resource, options = nil)
    github_creds = service_creds('github')
    account = github_creds["account"] || "#{ENV["GITHUB_REPO"]}-io"
    repo = github_creds["repo"] || 'services'
    ref = github_creds["ref"] || 'main'
    url = "#{service_creds('github_api')["url"]}/repos/#{account}/#{repo}/contents/#{resource}?ref=#{ref}"
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"
    response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: uri.scheme == "https", verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end

  def request_githubusercontent(resource, options = nil)
    github_creds = service_creds('github')
    account = github_creds["account"] || "#{ENV["GITHUB_REPO"]}-io"
    repo = github_creds["repo"] || 'services'
    ref = github_creds["ref"] || 'main'
    url = "https://raw.githubusercontent.com/#{account}/#{repo}/#{ref}/#{resource}?#{options}"
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"
    response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: uri.scheme == "https", verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end

  def request_openshift(resource, options = nil)
    os_creds = service_creds('os_api')
    url = os_creds["url"]
    url = "#{url}/#{resource}?#{options}"
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{os_creds["token"]}"
    response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: uri.scheme == "https", verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end

  def request_api_github(resource, options = nil)
    account = service_creds('github')["account"] || "#{ENV["GITHUB_REPO"]}-io"
    repo = service_creds('github')["repo"] || 'services'
    url = service_creds('github_api')["url"]
    ref = service_creds('github')["ref"] || 'main'
    url = "#{url}/repos/#{account}/#{repo}/contents/#{resource}?ref=#{ref}"
    uri = URI.parse(url)
    get_request_api_github(uri)
  end

  def request_raw_github(resource, options = nil)
    account = service_creds('github')["account"] || "#{ENV["GITHUB_REPO"]}-io"
    repo = service_creds('github')["repo"] || 'services'
    ref = service_creds('github')["ref"] || 'main'

    url = "https://raw.githubusercontent.com/#{account}/#{repo}/#{ref}/#{resource}?#{options}"
    uri = URI.parse(url)

    get_request_api_github(uri)
  end

  def get_request_api_os(resource, options = nil)
    os_creds = service_creds('os_api')
    url = os_creds["url"]
    url = "#{url}/#{resource}"
    url += "?#{options}" if options
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{os_creds["token"]}"
    do_request(request, uri)
  end

  def patch_request_api_os(resource, body)
    os_creds = service_creds("os_api")
    url = os_creds["url"]
    url = "#{url}/#{resource}"

    uri = URI.parse(url)

    request = Net::HTTP::Patch.new(uri)
    request.content_type = "application/merge-patch+json"
    request["Authorization"] = "Bearer #{os_creds["token"]}"
    request["Accept"] = "application/json"
    request.body = body

    do_request(request, uri)
  end

  def post_request_api_os(resource, body)
    os_creds = service_creds("os_api")
    url = os_creds["url"]
    url = "#{url}/#{resource}"

    uri = URI.parse(url)

    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{os_creds["token"]}"
    request["Accept"] = "application/json"
    request.body = body
    do_request(request, uri)
  end

  def put_request_api_os(resource, body)
    os_creds = service_creds("os_api")
    url = os_creds["url"]
    url = "#{url}/#{resource}"
    uri = URI.parse(url)

    request = Net::HTTP::Put.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{os_creds["token"]}"
    request["Accept"] = "application/json"
    request.body = body

    do_request(request, uri)
  end

  def delete_request_api_os(resource)
    os_creds = service_creds("os_api")
    url = os_creds["url"]
    url = "#{url}/#{resource}"
    uri = URI.parse(url)

    request = Net::HTTP::Delete.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{os_creds["token"]}"
    request["Accept"] = "application/json"

    do_request(request, uri)
  end

  def get_request_api_github(uri)
    request = Net::HTTP::Get.new(uri)
    #request.basic_auth(ENV['GITHUB_USER_NAME'], ENV['GITHUB_USER_TOKEN'])
    request["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"
    do_request(request, uri)
  end

  def check_service_accessibility(url)
    uri = URI.parse(url)
    request = Net::HTTP::Head.new(uri)
    request_result = do_request(request, uri)

    return 'FAIL' if request_result.class.eql?('String')
    return 'OK' if request_result
  end

  def do_request(request, uri)
    response = Net::HTTP.start(uri.hostname, uri.port, req_options(uri)) do |http|
      http.request(request)
    end

    return JSON.parse(response.body) if (response.code[0] == '2') || (response.code[0] == '3')
    return response.code
  rescue
    return '400'
  end

  def req_options(uri)
    {
      use_ssl: uri.scheme == "https",
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }
  end

end
