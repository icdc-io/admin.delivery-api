module SystemServices
  include OsHelper
  include GithubHelper

  def image_stream_by_service(service_name)
    list_images.each do |image|
      is = image_stream(image) 
      name = image_stream_name(is)
      return is if name.eql?(service_name)
    end
  end

  def image_stream_name(stream_hash)
    stream_hash.dig('metadata','name')
  end

  def image_stream_version(stream_hash)
    stream_hash.dig('spec','tags').select { |tag| tag['name'] == 'latest' }.first.dig('from','name')
  end

  def release_version(stream_hash) # tbd : add more params
    version = image_stream_version(stream_hash)
    {
      installed_service_version:installed_service_version(stream_hash["metadata"]),
      installed_release_version:installed_release_version(stream_hash["metadata"]),
      available_release_version:version,
      available_service_version:service_version_of_release(stream_hash, version),
      service_version_change_log:changelog_version(stream_hash)
    }
  end

  def installed_version(stream_hash)
    {
       installed_service_version:installed_service_version(stream_hash["metadata"]), #tbd :add info from OS
       service_version_change_log:changelog_version(stream_hash)
    }
  end

  def update_version(stream_hash)
    version = image_stream_version(stream_hash)
    {
       installed_service_version:installed_service_version(stream_hash["metadata"]), #tbd :add info from OS
       installed_release_version:installed_release_version(stream_hash["metadata"]),
       available_service_version:service_version_of_release(stream_hash, version),
       service_version_change_log:changelog_version(stream_hash)
    }
  end

  def update_service_version(stream_hash, version)
    is = installed_version(stream_hash)
    sr = service_repository(stream_hash["metadata"], version)
    create_image_stream_tag(stream_hash["metadata"]["name"], version, sr)
    set_image_tag(stream_hash["metadata"], version)
  end

  def service_version_of_release(stream_hash, release_version)
    stream_hash['spec']['tags'].select { |tag| tag['name'] == release_version }.first['from']['name']
  end

  def downgrade_service_version(stream_hash)
    set_image_tag(stream_hash["metadata"], stream_hash[:version])
  end

  def choose_version_to_downgrade(stream_hash)
    installed = []
    installed << installed_service_version(stream_hash["metadata"])
    all = all_installed_version(stream_hash["metadata"])
    downgraded = all - installed
  end

end
