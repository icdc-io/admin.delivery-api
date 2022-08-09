require 'yaml'

class Api::V1::ServicesController < ApplicationController
  include SystemServices
  include OsCommonHelper
  include OsHelper
  before_action :login

  def index
    image_names = list_images
    services = []
    image_names.each do |name|
      begin
        data = image_stream(name)
        data['json'] = name
        services << {name: image_stream_name(data), release_version:release_version(data), update_version:updated_version(data), installed_version:installed_version(data)}
      rescue => err
        next
      end
    end
    render json:services
  end

  def overview
    metadata = find_template(params[:service_name])
    result = {}
    result[:service_name] = metadata.dig('metadata','annotations','openshift.io/display-name')
    result[:description]  = metadata.dig('metadata','annotations','description')
    result[:documentation_url] = metadata.dig('metadata','annotations','openshift.io/documentation-url')
    render json:result
  end

  def create
    return abort("No such namespace") unless get_all_namespaces.include?(get_os_namespace(params[:service_name]))
    service_name = params[:service_name]
    required_service = get_latest_versions(service_name).select{|service| service["version"] == params["version"]}.first
    installed_version = get_latest_versions(service_name)
    installed_version = installed_version.map{ |tag| tag if tag["version"] == "latest"} unless installed_version == "404"
    # if installed_version.split(".").join.to_i <  required_service["version"].split(".").join.to_i
    #   update_service(service_name, required_service)
    # end
    deploy_template(service_name, required_service)
  end

  def delete
    $deleting[params[:service_name]] = "deleting"
    10.times do
      delete_code = delete_service(params[:service_name], params[:delete_persistent_data])
      if delete_code.to_i == 204
        $deleting.delete(params[:service_name])
        return '204'
      end
      sleep 5
    end
  end

  def downgrade
    required_version = get_required_version(params[:service_name], params[:version]).select{|tst|  tst if tst["version"] == params[:version]}.first
    update_service(params[:service_name], required_version)
    no_content
  end

  def update
    service_name = params[:service_name]
    latest_release_version = get_service_latest_version(service_name)
    latest_release = get_installed_service(service_name)["spec"]["tags"].map do |tag|
      tag["from"]["name"] if tag["name"] == "latest"
    end.compact.first unless latest_release == "404"
    if latest_release_version != latest_release
      metadata = request_raw_github("changelogs/#{params[:service_name]}/release-#{latest_release_version.split(".")[...-1].join(".")}.json").first
      update_service(service_name, metadata)
      success("Updated")
    end
    no_content
  end

  def upgrade
    service_name = params[:service_name]
    latest_release_version = get_service_latest_version(service_name)
    latest_release = get_installed_service(service_name)
    latest_release["spec"]["tags"].map do |tag|
      tag["from"]["name"] if tag["name"] == "latest"
    end.compact.first unless latest_release == "404"
    if latest_release_version != latest_release
      metadata =  get_required_latest_versions(service_name, latest_version_from_git).select{|service| service["version"] == params["version"]}.first
      latest_release = latest_release["spec"]["tags"].map{ |tag| tag["from"]["name"] if tag["name"] == "latest"} unless latest_release == "404"
      if latest_release.split(".").join.to_i <  metadata["version"].split(".").join.to_i
        update_service(service_name, metadata)
      end
      deploy_template(service_name, metadata)
    end
  end
end
