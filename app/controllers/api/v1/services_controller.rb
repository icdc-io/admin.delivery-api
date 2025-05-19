require 'yaml'

class Api::V1::ServicesController < ApplicationController
  include SystemServices
  include OsCommonHelper
  include OsHelper
  include OsCreateHelper
  include OsDeleteHelper
  include ServiceHelper
  # before_action :login
  before_action :operator_required

  def index
    prefix = ENV.fetch('NAMESPACE_PREFIX', 'cloud')
    namespaces = get_all_namespaces.select { |ns| ns.start_with?(prefix) }
    services = namespaces.map do |namespace|
      @namespace = namespace
      service_name = @namespace.split('-').last
      service_data(service_name)
    end.compact
    render json: services
  end

  def show
    service = service_data(params[:service_name])
    return render json: { message: 'Bad request, service not found', code: 404 }, status: :not_found unless service

    render json: service, status: :ok
  end

  # def index
  #   image_names = list_images
  #   services = []
  #   image_names.each do |name|
  #     begin
  #       data = image_stream(name)
  #       data['json'] = name
  #       services << {name: image_stream_name(data), release_version:release_version(data), update_version:updated_version(data), installed_version:installed_version(data)}
  #     rescue => err
  #       next
  #     end
  #   end
  #   render json:services
  # end

  def overview
    service = get_installed_service(params[:service_name])
    latest_version = service["spec"]["tags"].collect{|tag| tag["from"]["name"] if tag["name"] == "latest"}.compact.first
    service_version = describe_service_version(params[:service_name], latest_version).dig(0)

    render json: service_version, status: :ok
  rescue
    nil
  end

  def create
    prefix = ENV['NAMESPACE_PREFIX'] || 'cloud'

    unless get_all_namespaces.include?("#{prefix}-#{params[:service_name]}")
      create_namespace(params[:service_name])
    end

    service_name = params[:service_name]
    service = get_latest_versions(service_name).select{|service| service["version"] == params["version"]}.first

    #required_services = service["required"]
    #installed_version = get_installed_service(service_name)
    # required_services.keys.each do |required_service|
    #   installed_version = get_installed_service(required_service)
    #   next if installed_version == "404"
    #   if installed_version.split(".").join.to_i <  required_service["version"].split(".").join.to_i
    #     update_service(service_name, required_service) if installed_version.split(".").join.to_i != 0
    #   end
    # end

    deploy_template(service_name, service)

    #update
    service_name = params[:service_name]
    update_service(service_name, service)
    ServiceDiscoverer.instance.invalidate_cache
    no_content
  end

  def delete
    $deleting[params[:service_name]] = "deleting"
    10.times do
      delete_code = delete_service(params[:service_name], params[:delete_persistent_data], params[:delete_backup_data])
      if delete_code.to_i == 204
        $deleting.delete(params[:service_name])
        #delete_dns_record(params[:service_name])
        template = get_service_repository(params[:service_name])
        delete_dns_records(template)
        ServiceDiscoverer.instance.invalidate_cache

        return '204'
      end
      sleep 5
    end
  end

  def downgrade
    required_version = get_required_version(params[:service_name], params[:version]).select{|tst|  tst if tst["version"] == params[:version]}.first
    update_service(params[:service_name], required_version)
    ServiceDiscoverer.instance.invalidate_cache
    no_content
  end

  def upgrade
    return abort("No such namespace") unless get_all_namespaces.include?(get_os_namespace(params[:service_name]))
    service_name = params[:service_name]
    service = get_latest_versions(service_name).select{|service| service["version"] == params[:version]}.first
    deploy_template(service_name, service)
    service_name = params[:service_name]
    update_service(service_name, service)
    ServiceDiscoverer.instance.invalidate_cache
    no_content
  end

  private

  def service_data(service_name)
    service = service_image_stream(service_name)
    return if service['code'] == 404

    name = service.dig('metadata', 'name')
    tags = service.dig('spec', 'tags')
    current_version = installed_version(tags)
    downgrade_versions = all_installed_versions(tags).take_while { |version| version != current_version }
    current_release_version = current_version.split('.')[0...2].join('.')
    versions_from_release = release_changelogs(service_name, current_release_version)
    update_version = latest_update_version(versions_from_release, current_version)
    upgrade_version = latest_upgrade_version(service_name, current_release_version)
    { name:, current_version:, downgrade_versions:, update_version:, upgrade_version: }
  end

  # TODO: move methods to the helpers
  def installed_version(tags)
    tags.find { |tag| tag['name'] == 'latest' }&.dig('from', 'name')
  end

  def service_image_stream(service_name)
    @namespace ||= get_os_namespace(service_name)
    request_openshift("apis/image.openshift.io/v1/namespaces/#{@namespace}/imagestreams/#{service_name}")
  end

  def all_installed_versions(tags)
    tags.map { |tag| tag['name'] if tag['name'] != 'latest' }.compact
  end

  def release_changelogs(service_name, release_version)
    request_githubusercontent("changelogs/#{service_name}/release-#{release_version}.json")
  end

  def latest_update_version(versions_list, current_version)
    versions_list.take_while { |version| version['version'] != current_version }
                 .find { |x| x['tag'].empty? && x['version'] != current_version }
  end

  def latest_release_version(service_name)
    releases_list = ServiceChangelogs.instance.get_cached
    releases_list = ServiceChangelogs.instance.build_cache if releases_list['ttl'] < DateTime.now.to_i
    release_version = releases_list[service_name].keys.max_by { |release| Gem::Version.new(release) }
    releases_list[service_name][release_version].max_by { |version| Gem::Version.new(version['version']) }
  end

  def latest_upgrade_version(service_name, current_release_version)
    upgrade_version = latest_release_version(service_name)
    upgrade_version = 'release is actual' if current_release_version == upgrade_version['release']
    upgrade_version
  end
end
