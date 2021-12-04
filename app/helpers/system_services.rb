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

  def release_version(stream_hash) 
    installed_service_version = installed_service_version(stream_hash["metadata"])
    available_release_version = image_stream_version(stream_hash)
    available_service_version = service_version_of_release(stream_hash, available_release_version)
    return {
       available_service_version:available_service_version,
       service_version_change_log:changelog_version(stream_hash)
    } if available_service_version != installed_service_version
  end

  def installed_version(stream_hash)
    {
       installed_service_version:installed_service_version(stream_hash["metadata"]), #tbd :add info from OS
       service_version_change_log:changelog_version(stream_hash)
    }
  end

  def updated_version(stream_hash)
    installed_service_version = installed_service_version(stream_hash["metadata"])
    installed_release_version = installed_release_version(stream_hash["metadata"])
    available_service_version = service_version_of_release(stream_hash, installed_release_version)
    return {
       available_service_version:available_service_version,
       service_version_change_log:changelog_version(stream_hash)
    } if available_service_version != installed_service_version
  end

  def update_service_version(stream_hash)
    up = updated_version(stream_hash)&[:available_service_version]
    return "No available version for update." unless up
    sr = service_repository(stream_hash, up)
    create_image_stream_tag(stream_hash["metadata"]["name"], up, sr)
    set_image_tag(stream_hash["metadata"], up)
  end

  def upgrade_service_version(stream_hash)
    up = release_version(stream_hash).dig(:available_service_version)
    return "No available version for upgrade." unless up
    sr = service_repository(stream_hash, up)
    create_image_stream_tag(stream_hash["metadata"]["name"], up, sr)
    set_image_tag(stream_hash["metadata"], up)
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
