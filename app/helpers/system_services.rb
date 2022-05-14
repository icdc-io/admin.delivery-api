module SystemServices
  include OsHelper
  include GithubHelper
  include ImageHelper

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
    return "No version for release"
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
    return "No version for updating"
  end

  def update_service_version(stream_hash)
    up = updated_version(stream_hash).dig('available_service_version')
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
    return "No version to downgrade" if downgraded.empty?
  end

  def service_status(service_name)
    img_streams = image_streams(service_name)
    service_installed = false unless img_streams
    service_installed = true if img_streams
    service_status = 'deleting' if (File.exist?('Hello.rb'))
    revision = get_deployment_config_revision(service_name)
    replication_status = get_replication_controller_status(service_name, revision)
    service_status = 'none' if replication_status.empty?
    service_status = 'running' if replication_status.eql?("Running")
    service_status = 'complete' if replication_status.eql?("Complete")
# If service_installed is false and Get PersistentVolumeClaim is false, set service_deleted to true, else set service_deleted to false
    service_deleted = true unless service_installed ^ get_pvc(service_name)
    service_deleted = false if service_installed ^ get_pvc(service_name)
    render json: {service_name: service_name, service_installed: service_installed, service_status: service_status}
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
    else
      "No option for check status"
    end
  end

  def check_service_access(location, service_name)
    template_hash = find_template(params[:service_name])
    domain = get_application_domain(template_hash, location)
    url = 'http://' + service_name + '.' + domain
    test = check_service_accessibility(url)
  end

  

  def check_istalled_status(location,service_name)
    stream_hash = image_stream_by_service(params[:service_name])
    revision = get_deployment_config_revision(stream_hash["metadata"]["name"])
    get_replication_controller_status(stream_hash["metadata"]["name"], revision)
  end
end
