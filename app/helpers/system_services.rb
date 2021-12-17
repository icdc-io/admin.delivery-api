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
    begin
      installed_service_version = installed_service_version(stream_hash["metadata"])
      available_release_version = image_stream_version(stream_hash)
      available_service_version = service_version_of_release(stream_hash, available_release_version)
      return {
        available_service_version:available_service_version,
        service_version_change_log:changelog_version(stream_hash)
      } if available_service_version != installed_service_version
    rescue
    end
    {}
  end

  def installed_version(stream_hash)
    begin 
      {
         installed_service_version:installed_service_version(stream_hash["metadata"]), #tbd :add info from OS
         service_version_change_log:changelog_version(stream_hash)
      }
    rescue
      {}
    end
    
  end

  def updated_version(stream_hash)
    begin
      installed_service_version = installed_service_version(stream_hash["metadata"])
      installed_release_version = installed_release_version(stream_hash["metadata"])
      available_service_version = service_version_of_release(stream_hash, installed_release_version)
      return {
        available_service_version:available_service_version,
        service_version_change_log:changelog_version(stream_hash)
      } if available_service_version != installed_service_version
    rescue
    end
    {}
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

  def check_status(location, service_name, option, delete_persistent_data)
    case option
    when 'check'
      check_service_access(location, service_name)
    when 'update'
      check_updated_status(service_name)
    when 'install'
      check_installed_status(location, service_name)
    when 'delete'
      check_deleted_status(service_name,delete_persistent_data)
    end
  end

  def check_service_access(location, service_name)
    template_hash = find_template(params[:service_name])
    domain = get_application_domain(template_hash, location)
    url = service_name + '.' + domain
    test = check_service_accessibility("https://www.onliner.by/")
    raise "#{test}_______#{url}"
  end

  def check_istalled_status(location,service_name)
    stream_hash = image_stream_by_service(params[:service_name])
    revision = get_deployment_config_revision(stream_hash["metadata"]["name"])
    status = get_replication_controller_status(stream_hash["metadata"]["name"], revision)
    check_service_access(location, service_name) if status.eql?('Complete')
    # what shold be done ic case of 'Running'?
  end
end
