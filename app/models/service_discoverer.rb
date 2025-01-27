class ServiceDiscoverer
  include Singleton

  include OsHelper
  include SystemServices

  attr_accessor :services_cache

  def services
    get_services_cache
  end

  def get_services_cache
    unless self.services_cache
      self.services_cache = discovery_services
    end

    self.services_cache
  end

  def discovery_services
    Rails.logger.info { '[ServiceDiscoverer] building services apps cache' }
    services = services_list
    services_versions = services.filter_map { |s| installed_version(s)}.inject(&:merge)

    services_versions.filter_map do |service, version|
      service_info(service, version).find { _1["version"] == version }
    end
  end

  private

  def service_info(service, version)
    Rails.logger.info { "[ServiceDiscoverer] fetching #{service}-#{version} info" }
    resp = request_api_github("applications/#{service}/#{release_filename(version)}")
    if resp == "404"
      Rails.logger.warn { "[ServiceDiscoverer] #{service}-#{version} was not found"}
    end
    decode_content resp["content"]
  end

  def installed_version(name)
    image_stream = get_installed_service(name)
    return if image_stream == "404"

    tags = image_stream.dig('spec', 'tags')

    version = tags.find { _1['name'] == 'latest' }.dig('from','name')

    { name => version }
  end

  def services_list
    Rails.logger.info { '[ServiceDiscoverer] fetching list of installed services...' }
    valid_namespaces(get_all_namespaces).map { _1.gsub("#{prefix}-", '')}
  end

  def valid_namespaces(namespaces)
    namespaces.reject { |namespace| namespace unless namespace.start_with? prefix }
  end

  def prefix
    ENV.fetch('NAMESPACE_PREFIX', 'cloud')
  end

  def release_filename(version)
    version.split('.')[0..1].join(".") + ".json"
  end

  def decode_content(content)
    JSON.parse Base64.decode64(content)
  end
end
