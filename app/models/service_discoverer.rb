# frozen_string_literal: true

class ServiceDiscoverer
  include Singleton
  include Authenticator
  include OkdRequestHelper

  def build_cache
    if mutex.lock
      begin
        discovered_services = discovery_services.to_json
        cache_store.set('discovered_services', discovered_services)
      ensure
        mutex.unlock
      end
      discovered_services
    else
      Rails.logger.warn { '[ServiceDiscoverer::build_cache] can not access to a locked cache' }
    end
  rescue StandardError => e
    Rails.logger.error { "[ServiceDiscoverer:build_cache] can't build cache in redis, skipping... #{e.message}" }
  end

  def get_cached
    if cache_store
      response = JSON.parse cache_store.get('discovered_services')
      response ||= build_cache
    else
      Rails.logger.warn { '[ServiceDiscoverer:get_cache] cache was skipped...' }
      response = discovery_services
    end

    response.map(&:deep_symbolize_keys)
  end

  def invalidate_cache
    cache_store.set('discovered_services', nil)
  rescue StandardError => e
    Rails.logger.error { "[ServiceDiscoverer:invalidate_cache] can't invalidate cache... #{e.message}" }
  end

  private

  def cache_store
    @cache_store ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'))
  rescue => e
    Rails.logger.error { "[ServiceDiscoverer:cache_store] can't connect to a redis-server, skipping cache... #{e.message}" }
    nil
  end

  def mutex
    RedisClassy.redis = cache_store
    RedisMutex.new('discovered_services', expire: 30)
  end

  def discovery_services
    Rails.logger.info { '[ServiceDiscoverer:discovery_services] building services apps cache...' }
    build_services_versions
  end

  def build_services_versions
    services_list.filter_map do |service|
      version = installed_version_for(service)
      next unless version

      service_details(service, version)
    end.compact + central_location_services.to_a
  end

  def service_details(service, version)
    info = service_info(service, version)&.detect { _1['version'] == version }
    location_service = location_services.detect { _1['name'] == service }

    return unless info && location_service

    info.merge(
      description: location_service['description'],
      position: location_service['position'],
      display_name: location_service['display_name'],
      path: location_service['path'],
      url: location_service['url']
    )
  end

  def location_services
    @location_services ||= JSON.parse(location_response.body)['locations'].detect do |loc|
      loc['name'] == ENV['LOCATION_NAME']
    end['services']
  end

  def central_location_services
    services_names = GithubClient.get_resource('applications/_central').map { _1['name'].gsub('.json', '') }

    services_names.filter_map do |service|
      info = service_info(service)
      location_service = location_services.detect { _1['name'] == service }

      return unless info && location_service

      info.merge(
        description: location_service['description'],
        position: location_service['position'],
        display_name: location_service['display_name'],
        path: location_service['path'],
        url: location_service['url']
      )
    end
  end

  def location_response
    RestClient.get(
      "#{ENV['CPV_API_GATEWAY']}/api/accounts/v1/account",
      authorization_headers
    )
  end

  def authorization_headers
    {
      'x-auth-group': ENV['OPERATOR_GROUP'],
      Authorization: "Bearer #{operator_jwt}"
    }
  end

  def service_info(service, version = nil)
    Rails.logger.info { "[ServiceDiscoverer] fetching #{service}: #{version} info" }
    content = fetch_service_content(service, version)
    decode_content(content) unless content == '404'
  end

  def fetch_service_content(service, version = nil)
    url = 'applications'

    url += if version
             "/#{service}/#{release_filename(version)}"
           else
             "/_central/#{service}.json"
           end

    GithubClient.get_resource(url)
  end

  def installed_version_for(service)
    image_stream = OkdClient.get_service_imagestream(service)
    get_resource("apis/image.openshift.io/v1/namespaces/#{OkdClient.namespace(service)}/imagestreams/#{service}")
    return if image_stream == '404'

    image_stream.dig('spec', 'tags')&.detect { _1['name'] == 'latest' }&.dig('from', 'name')
  end

  def services_list
    Rails.logger.info { '[ServiceDiscoverer:service_list] fetching installed services...' }
    valid_namespaces.map { |ns| ns.gsub("#{prefix}-", '') }
  end

  def valid_namespaces
    OkdClient.namespaces.select { |ns| ns.start_with?(prefix) }
  end

  def prefix
    ENV.fetch('NAMESPACE_PREFIX', 'cloud')
  end

  def release_filename(version)
    version.split('.')[0..1].join('.') + '.json'
  end

  def decode_content(content)
    JSON.parse(Base64.decode64(content['content']))
  end
end
