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
      if response.empty?
        build_cache
        response = discovery_services
      end
    else
      Rails.logger.warn { '[ServiceDiscoverer:get_cache] cache was skipped...' }
      response = discovery_services
    end

    response.map(&:deep_symbolize_keys)
  end

  def invalidate_cache
    cache_store.set('discovered_services', {})
  rescue StandardError => e
    Rails.logger.error { "[ServiceDiscoverer:invalidate_cache] can't invalidate cache... #{e.message}" }
  end

  private

  def cache_store
    @cache_store ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'))
  rescue StandardError => e
    Rails.logger.error do
      "[ServiceDiscoverer:cache_store] can't connect to a redis-server, skipping cache... #{e.message}"
    end
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

  def external_services()
    @external_services ||= ENV.fetch('EXTERNAL_SERVICES', 'disk,code').split(',')
  end

  def build_services_versions
    (central_services + location_services).filter_map do |entitled_service|
      service_name = entitled_service[:name]
      if external_services().include?(service_name)
        # For external services (like code, disk, account) entitlement means => installed
        Rails.logger.info("[ServiceDiscoverer#build_services_versions] Entitled service is externally managed: #{service_name}")
        # TODO: may be pull version from CRM specification (need to add new field and track it)
        version = "0.0.0"
      else
        version = installed_version_for(service_name) # e.g. "1.7.0"
        Rails.logger.info("[ServiceDiscoverer#build_services_versions] Installed version of the entitled service: #{service_name}:#{version}")
        next unless version
      end
      service_details(entitled_service, version)
    end.compact
  end

  def central_services
    return [
      { name: "core" }, # Special non-visible service for chrome and home apps versioning
      { name: "account" }
    ]
  end

  # NOTE: return symbolized keys
  def location_services
    @location_services ||= JSON.parse(location_response.body)['locations'].detect do |loc|
      loc['name'] == ENV.fetch('LOCATION_NAME')
    end['services'].map(&:deep_symbolize_keys)
  end

  def location_response
    RestClient.get(
      "#{ENV.fetch('CPV_API_GATEWAY')}/api/accounts/v1/account",
      authorization_headers
    )
  end

  def authorization_headers
    {
      'x-auth-group': ENV.fetch('OPERATOR_GROUP'),
      Authorization: "Bearer #{operator_jwt}"
    }
  end

  def service_details(service, version)
    # Fetch versioned service information altogether with UI apps versions from Github specification file
    spec = fetch_service_spec(service[:name], version) || {}
    # Enrich service apps spec with entitled service info
    spec.merge(
      title: service.fetch(:display_name, spec[:title]),
      position: service[:position],
      description: service[:description],
      path: service[:path],
      url: service[:url]
    )
  end

  def fetch_service_spec(service_name, version)
    Rails.logger.info { "[ServiceDiscoverer] fetching #{service_name} apps specification: #{version} info" }
    # Try to load YAML specification first
    specs = GithubClient.get_yaml_resource("specs/#{service_name}.yml")
    if specs.empty?
      # Fallback to obsolete per-release JSON specifications
      specs = GithubClient.get_json_resource("applications/#{service_name}/#{release_filename(version)}")
    end
    specs.detect{ _1['version'] == version }&.deep_symbolize_keys unless specs.empty?
  end

  def installed_version_for(service)
    image_stream = OkdClient.get_service_imagestream(service)
    namespace = OkdClient.namespace(service)
    # Store central apps ImageStreams in core namespace
    namespace = "core" if ["core", "account"].include?(service)
    get_resource("apis/image.openshift.io/v1/namespaces/#{namespace}/imagestreams/#{service}")
    if image_stream == '404'
      # TODO: release-5.3 backward-compatibility for locations which is missing imagestreams in core namespace
      return "1.0.0" if namespace == "core"
      return
    end

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
end
