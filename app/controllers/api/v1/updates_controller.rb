class Api::V1::UpdatesController < ApplicationController
  include SystemServices
  # before_action :login
  before_action :operator_required

  def show
    installed_version = get_latest_image_version(params[:service_name])
    update_versions = request_raw_github("changelogs/#{params[:service_name]}/release-#{installed_version.split(".")[...-1].join(".")}.json")
    update_version = update_versions.find {|x| x["tag"] == "latest"}

    if installed_version != update_version["version"]
      render json: update_version
    else
      render json: nil
    end
  rescue
    render json: nil
  end

  def create
    service_name = params[:service_name]
    required_service = get_latest_versions(service_name).select{|service| service["version"] == params["version"]}.first
    update_service(service_name, required_service)
    no_content
  end

private
  def stream_hash
    image_stream_by_service(params[:service_name])
  end
end
