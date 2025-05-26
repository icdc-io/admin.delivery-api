# frozen_string_literal: true

include Authenticator
class GithubClient
  def self.download_urls(service_name)
    get_resource("changelogs/#{service_name}").select do |changelog|
      changelog['download_url']&.include?('release')
    end.map { |changelog| changelog['download_url'] }
  end

  def self.changelogs(service_name)
    releases = {}
    download_urls(service_name).map do |url|
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(uri.hostname, uri.port,
                                 { use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |http|
        http.request(request)
      end
      response = JSON.parse(response.body)
      release_version = response[0]['release']
      releases[release_version] = response
    end
    releases
  end

  def self.get_resource(resource, _options = nil)
    github_creds = service_creds('github')
    account = github_creds['account'] || "#{ENV['GITHUB_REPO']}-io"
    repo = github_creds['repo'] || 'services'
    ref = github_creds['ref'] || 'main'
    uri = URI.parse("#{service_creds('github_api')['url']}/repos/#{account}/#{repo}/contents/#{resource}?ref=#{ref}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{ENV['GITHUB_TOKEN']}"
    response = Net::HTTP.start(uri.hostname, uri.port,
                               { use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end
end
