class Admin::V1::VersionsController < ApplicationController
  include SystemServices
  before_action :login
  
  def show
    stream_hash = image_stream_by_service(params[:service_name])
    render json: installed_service_version(stream_hash["metadata"]) 
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    stream_hash[:version] = params[:version]
    render json:  downgrade_service_version(stream_hash)["tag"]["from"]["name"]
  end

  def downgrade_versions
    stream_hash = image_stream_by_service(params[:service_name])
    render json: choose_version_to_downgrade(stream_hash)
  end

  def installed_github_versions
    stream_hash = image_stream_by_service(params[:service_name])
    render json: service_versions(stream_hash)
  end
end
