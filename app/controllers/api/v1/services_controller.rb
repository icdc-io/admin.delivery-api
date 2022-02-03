require 'yaml'

class Api::V1::ServicesController < ApplicationController
  include SystemServices
  include GithubHelper
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

  def show
    is = image_stream_by_service(params[:service_name])
    service_installed = 'false' unless is
    service_installed = 'true' if is
    render json: {service_name:is.dig('metadata','name'), service_installed: service_installed} 
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
    create_namespace(params[:service_name])
    stream_hash = image_stream_by_service(params[:service_name])
    sr = service_repository(stream_hash, params[:version])
    create_image_stream_tag(stream_hash['metadata']['name'], params[:version], sr)
    set_image_tag(stream_hash['metadata'], params[:version])
    template = find_template(params[:service_name])
    template = update_template(template, params, get_location)
    source_hash = generate_service_template(template, params[:service_name])
    install_service(source_hash, params[:service_name])
  end

  def delete
    delete_service(params[:service_name], params[:delete_persistent_data]) 
  end
end
