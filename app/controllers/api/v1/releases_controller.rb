class Api::V1::ReleasesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    latest_release_version = get_service_latest_version(params[:service_name])
    required_service = get_required_latest_version(params[:service_name], latest_release_version)["version"]
    latest_release = get_installed_service(params[:service_name])["spec"]["tags"].map do |tag|
      tag["from"]["name"] if tag["name"] == "latest"
    end.compact.first unless latest_release == "404"
    if latest_release_version != latest_release
      metadata = request_raw_github("changelogs/#{params[:service_name]}/release-#{latest_release.split(".")[...-1].join(".")}.json").first
      return success(metadata)
    end
    success("release is actual")
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    render json: upgrade_service_version(stream_hash)
  end
end
