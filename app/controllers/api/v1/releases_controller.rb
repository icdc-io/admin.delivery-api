class Api::V1::ReleasesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    latest_release = get_latest_version(params[:service_name])
    installed_version = installed_service_version(params[:service_name])
    if installed_version != latest_release["version"]
      return success(latest_release)
    end
    success("release is actual")
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    render json: upgrade_service_version(stream_hash)
  end
end
