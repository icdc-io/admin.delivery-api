# frozen_string_literal: true

class ServiceChangelogs
  include Singleton
  include GithubHelper
  include OsHelper

  def build_cache
    prefix = ENV.fetch('NAMESPACE_PREFIX', 'cloud')
    namespaces = get_all_namespaces.select { |ns| ns.start_with?(prefix) }
    changelogs = {}
    namespaces.each do |namespace|
      service_name = namespace.gsub("#{prefix}-", '')
      changelogs.merge!(service_name => github_changelogs(service_name))
    end
    changelogs.merge!('ttl' => DateTime.now.to_i + 3600)
    cache_store.set('service_changelogs', changelogs.to_json)
    changelogs
  end

  def get_cached
    if cache_store
      response = cache_store.get('service_changelogs')
      response ||= build_cache
      JSON.parse(response)
    else
      Rails.logger.warn { '[ServiceChangelogs:get_cache] cache was skipped...' }
      github_changelogs(service_name)
    end
  end

  def invalidate_cache
    cache_store.set('service_changelogs', nil)
  rescue StandardError => e
    Rails.logger.error { "[ServiceChangelogs:invalidate_cache] can't invalidate cache... #{e.message}" }
  end

  private

  def cache_store
    @cache_store ||= Redis.new(url: ENV.fetch('REDIS_URL'))
  rescue StandardError => e
    Rails.logger.error do
      "[ServiceChangelogs:cache_store] can't connect to a redis-server, skipping cache... #{e.message}"
    end
    nil
  end

  def github_changelogs(service_name)
    download_urls = service_changelogs(service_name).select do |changelog|
      changelog['download_url']&.include?('release')
    end.map { |changelog| changelog['download_url'] }
    releases = {}
    download_urls.map do |url|
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
end
