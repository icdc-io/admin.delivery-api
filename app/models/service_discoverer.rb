class ServiceDiscoverer
  include Singleton
  include Authenticator
  include OsHelper
  include SystemServices

  attr_accessor :services_cache

  def cache
    unless self.services_cache
      self.services_cache = fetch_services_cache
    end
    self.services_cache
  end

  private

  def fetch_services_cache
    discovery_services.map(&:deep_symbolize_keys)
  end

  def discovery_services
    Rails.logger.info { '[ServiceDiscoverer] building services apps cache' }
    build_services_versions
  end

  def build_services_versions
    services_list.filter_map do |service|
      next unless (version = installed_version_for(service))

      service_details(service, version)
    end.compact
  end

  def service_details(service, version)
    info = service_info(service, version)&.detect { _1["version"] == version }
    location_service = location_services.detect { _1["name"] == service }
    return unless info && location_service

    info.merge(
      description: location_service["description"],
      position: location_service["position"],
      display_name: location_service["display_name"]
    )
  end

  def location_services
    @location_services ||= JSON.parse(location_response.body)["locations"].detect do |loc|
      loc["name"] == ENV["LOCATION_NAME"]
    end["services"]
  end

  def central_location_services

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

  def service_info(service, version)
    Rails.logger.info { "[ServiceDiscoverer] fetching #{service}-#{version} info" }
    content = fetch_service_content(service, version)
    decode_content(content) unless content == "404"
  end

  def fetch_service_content(service, version)
    request_api_github("applications/#{service}/#{release_filename(version)}")
  end

  def installed_version_for(service)
    image_stream = get_installed_service(service)
    return if image_stream == "404"

    image_stream.dig('spec', 'tags')&.detect { _1['name'] == 'latest' }&.dig('from', 'name')
  end

  def services_list
    Rails.logger.info { '[ServiceDiscoverer] fetching installed services...' }
    valid_namespaces.map { |ns| ns.gsub("#{prefix}-", '') }
  end

  def valid_namespaces
    get_all_namespaces.select { |ns| ns.start_with?(prefix) }
  end

  def prefix
    ENV.fetch('NAMESPACE_PREFIX', 'cloud')
  end

  def release_filename(version)
    version.split('.')[0..1].join(".") + ".json"
  end

  def decode_content(content)
    JSON.parse(Base64.decode64(content["content"]))
  end
end
