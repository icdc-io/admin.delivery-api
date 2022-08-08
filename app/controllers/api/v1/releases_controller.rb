class Api::V1::ReleasesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    latest_release_version = get_service_latest_version(params[:service_name]).split(".")[...-1].join(".")
    latest_release = get_release(params[:service_name])
    if latest_release_version != latest_release
      metadata = request_raw_github("changelogs/#{params[:service_name]}/release-#{latest_release}.json")
      return success(metadata.sort_by{|hash| hash["version"]})
    end
    success("release is actual")
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    render json: upgrade_service_version(stream_hash)
  end
end
