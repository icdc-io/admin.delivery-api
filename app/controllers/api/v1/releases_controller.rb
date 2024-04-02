class Api::V1::ReleasesController < ApplicationController
  include SystemServices
  before_action :login

#  def show
#    latest_release = get_latest_version(params[:service_name])
#    installed_version = installed_service_version(params[:service_name])
#    if installed_version != latest_release["version"]
#      return success(latest_release)
#    end
#    success("release is actual")
#  end

  def show
    latest_release = get_latest_version(params[:service_name])
    installed_version = installed_service_version(params[:service_name])
    unless installed_version.nil?
      update_versions = request_raw_github("changelogs/#{params[:service_name]}/release-#{installed_version.split(".")[...-1].join(".")}.json")
      update_version = update_versions.find {|x| x["tag"] == "latest"}

      return success(latest_release) unless update_version

      if installed_version != latest_release["version"] && update_version["version"] != latest_release["version"]
        return success(latest_release)
      end
      success("release is actual")
    else
      return success(latest_release)
    end
  rescue
    render json: nil
  end

  def create
    service_name = params[:service_name]
    stream_hash = image_stream_by_service(service_name)
    render json: upgrade_service_version(stream_hash, service_name)
  end
end
