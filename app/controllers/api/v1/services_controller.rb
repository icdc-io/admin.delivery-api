require 'yaml'

class Api::V1::ServicesController < ApplicationController
  include SystemServices
  include OsCommonHelper
  include OsHelper
  include OsCreateHelper
  include OsDeleteHelper
  include ServiceHelper
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
    no_content
  end

  def delete
    $deleting[params[:service_name]] = "deleting"
    10.times do
      delete_code = delete_service(params[:service_name], params[:delete_persistent_data])
      if delete_code.to_i == 204
        $deleting.delete(params[:service_name])
        #delete_dns_record(params[:service_name])
        template = get_service_repository(params[:service_name])
        delete_dns_records(template)
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


  def upgrade
    return abort("No such namespace") unless get_all_namespaces.include?(get_os_namespace(params[:service_name]))
    service_name = params[:service_name]
    service = get_latest_versions(service_name).select{|service| service["version"] == params[:version]}.first
    deploy_template(service_name, service)
    service_name = params[:service_name]
    update_service(service_name, service)
    no_content
  end
end
