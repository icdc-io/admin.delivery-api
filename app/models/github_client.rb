# frozen_string_literal: true

include Authenticator
class GithubClient
  attr_reader :creds, :account, :repo, :ref, :api_url, :token

  def initialize
    @creds = service_creds('github')
    @account = creds['account'] || "#{ENV.fetch('GITHUB_REPO')}-io"
    @repo = creds['repo'] || 'services'
    @ref = creds['ref'] || 'main'
    @api_url = service_creds('github_api')['url']
    @token = ENV.fetch('GITHUB_TOKEN')
  end

  def self.registry_server(service_name)
    template = Template.find_by(service_name:)
    ENV.fetch('REGISTRY_SERVER', template['parameters']&.find { |x| x['name'] == 'REGISTRY_SERVER' }&.dig('value'))
  end

  def self.changelogs(service_name)
    download_urls = GithubClient.get_resource("changelogs/#{service_name}").map do |changelog|
      changelog['download_url'] if changelog['download_url']&.include?('release')
    end.compact
    releases = {}
    download_urls.map do |url|
      response = RestClient::Request.execute(
        method: :get,
        url: url,
        verify_ssl: ENV.fetch('VERIFY_SSL', false)
      )
      response = JSON.parse(response.body)
      release_version = response.dig(0, 'release')
      releases[release_version] = response
    end
    releases
  end

  def self.get_yaml_resource(path)
    content = self.get_resource(path)
    return content if content.empty?
    YAML.load(Base64.decode64(content['content']))
  end

  def self.get_json_resource(path)
    content = self.get_resource(path)
    return content if content.empty?
    JSON.parse(Base64.decode64(content['content']))
  end

  def self.get_resource(resource)
    github_client = GithubClient.new
    url = "#{github_client.api_url}/repos/#{github_client.account}/#{github_client.repo}/contents/#{resource}?ref=#{github_client.ref}"
    response = RestClient::Request.execute(
      method: :get,
      url: url,
      headers: {
        Authorization: "Bearer #{github_client.token}"
      },
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)
  rescue RestClient::NotFound
    []
  end

  def self.get_githubusercontent_resource(resource, options = nil)
    github_client = GithubClient.new
    url = "https://raw.githubusercontent.com/#{github_client.account}/#{github_client.repo}/#{github_client.ref}/#{resource}?#{options}"
    response = RestClient::Request.execute(
      method: :get,
      url: url,
      headers: {
        Authorization: "Bearer #{github_client.token}"
      },
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)
  rescue RestClient::NotFound
    {}
  end
end
