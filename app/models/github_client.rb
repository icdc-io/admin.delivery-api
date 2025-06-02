# frozen_string_literal: true

include Authenticator
include RequestHelper
class GithubClient
  def self.registry_server(service_name)
    template = Github::Template.find_by_service_name(service_name)
    ENV['REGISTRY_SERVER'] || template['parameters'].find { |x| x['name'] == 'REGISTRY_SERVER' }['value']
  end

  def self.changelogs(service_name)
    download_urls = get_resource("changelogs/#{service_name}").select do |changelog|
      changelog['download_url']&.include?('release')
    end.map { |changelog| changelog['download_url'] }
    releases = {}
    download_urls.map do |url|
      response = RestClient::Request.execute(
        method: :get,
        url: url,
        verify_ssl: Rails.env.production?
      )
      response = JSON.parse(response.body)
      release_version = response[0]['release']
      releases[release_version] = response
    end
    releases
  end

  def self.get_resource(resource)
    github_creds = service_creds('github')
    account = github_creds['account'] || "#{ENV['GITHUB_REPO']}-io"
    repo = github_creds['repo'] || 'services'
    ref = github_creds['ref'] || 'main'
    url = "#{service_creds('github_api')['url']}/repos/#{account}/#{repo}/contents/#{resource}?ref=#{ref}"
    response = RestClient::Request.execute(
      method: :get,
      url: url,
      headers: {
        Authorization: "Bearer #{ENV['GITHUB_TOKEN']}"
      },
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)
  rescue RestClient::NotFound
    []
  end

  def self.get_githubusercontent_resource(resource, options = nil)
    github_creds = service_creds('github')
    account = github_creds["account"] || "#{ENV["GITHUB_REPO"]}-io"
    repo = github_creds["repo"] || 'services'
    ref = github_creds["ref"] || 'main'

    url = "https://raw.githubusercontent.com/#{account}/#{repo}/#{ref}/#{resource}?#{options}"
    response = RestClient::Request.execute(
      method: :get,
      url: url,
      headers: {
        Authorization: "Bearer #{ENV['GITHUB_TOKEN']}"
      },
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)
    rescue RestClient::NotFound
      {}
  end
end
