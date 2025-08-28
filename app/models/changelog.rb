# frozen_string_literal: true

class Changelog
  include Singleton

  def build_cache
    prefix = ENV.fetch('NAMESPACE_PREFIX', 'cloud')
    namespaces = OkdClient.namespaces(prefix)
    changelogs = {}
    namespaces.each do |namespace|
      service_name = namespace.gsub("#{prefix}-", '')
      changelogs.merge!(service_name => GithubClient.changelogs(service_name))
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
      Rails.logger.warn { '[Changelog:get_cache] cache was skipped...' }
      GithubClient.changelogs(service_name)
    end
  end

  def invalidate_cache
    cache_store.set('service_changelogs', {})
  rescue StandardError => e
    Rails.logger.error { "[Changelog:invalidate_cache] can't invalidate cache... #{e.message}" }
  end

  def self.all
    releases_list = Changelog.instance.get_cached
    releases_list = Changelog.instance.build_cache if releases_list['ttl'] < DateTime.now.to_i
    releases_list
  end

  def self.platform_version(service_name, current_version, current_release)
    all.dig(service_name, current_release)&.find do |changelog|
      changelog['version'] == current_version
    end&.dig('platform_version')
  end

  def self.update_versions(service_name, current_version, current_release)
    all.dig(service_name, current_release)
       &.take_while { |version| version['version'] != current_version }
       &.sort_by { |version| Gem::Version.new(version['version']) }&.reverse
  end

  def self.upgrade_versions(service_name, current_release)
    versions = all[service_name].select do |release, _versions|
      Gem::Version.new(release) > Gem::Version.new(current_release)
    end.values.flatten.sort_by { |version| Gem::Version.new(version['version']) }.reverse
    versions = versions.select { |version| version['tag'] == 'latest' } unless current_release
    versions
  end

  def self.find_version(service_name, version)
    release_version = version.split('.')[0...2].join('.')
    all.dig(service_name, release_version)&.find { |release| release['version'] == version }
  end

  private

  def cache_store
    @cache_store ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'))
  rescue StandardError => e
    Rails.logger.error do
      "[Changelog:cache_store] can't connect to a redis-server, skipping cache... #{e.message}"
    end
    nil
  end
end
