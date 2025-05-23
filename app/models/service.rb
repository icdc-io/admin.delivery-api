# frozen_string_literal: true

class Service
  def self.all
    OKD::ImageStream.all.map do |image_stream|
      service_data(image_stream)
    end
  end

  def self.find_by_name(name)
    image_stream = OKD::ImageStream.get(name)
    return unless image_stream

    service_data(image_stream)
  end

  def self.service_data(image_stream)
    name = image_stream.name
    current_version = image_stream.current_version
    downgrade_versions = image_stream.downgrade_versions
    current_release_version = image_stream.current_release_version
    update_version = latest_update_version(name, current_version, current_release_version)
    upgrade_version = latest_upgrade_version(name, current_release_version)
    { name:, current_version:, downgrade_versions:, update_version:, upgrade_version: }
  end

  def self.latest_update_version(service_name, current_version, current_release_version)
    versions_list = release_changelogs(service_name, current_release_version)
    versions_list&.take_while { |version| version['version'] != current_version }
                 &.find { |x| x['tag'].empty? && x['version'] != current_version }
  end

  def self.latest_upgrade_version(service_name, current_release_version)
    upgrade_version = latest_release_version(service_name)
    return 'release is actual' unless upgrade_version

    if Gem::Version.new(current_release_version) >= Gem::Version.new(upgrade_version['release'])
      upgrade_version = 'release is actual'
    end
    upgrade_version
  end

  def self.latest_release_version(service_name)
    releases_list = changelogs_cache
    release_version = releases_list[service_name].keys&.max_by { |release| Gem::Version.new(release) }
    releases_list.dig(service_name, release_version)&.max_by { |version| Gem::Version.new(version['version']) }
  end

  def self.release_changelogs(service_name, current_release_version)
    releases_list = changelogs_cache
    releases_list.dig(service_name, current_release_version)
  end

  def self.changelogs_cache
    releases_list = ServiceChangelogs.instance.get_cached
    releases_list = ServiceChangelogs.instance.build_cache if releases_list['ttl'] < DateTime.now.to_i
    releases_list
  end
end
