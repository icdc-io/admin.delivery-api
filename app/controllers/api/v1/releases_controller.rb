class Api::V1::ReleasesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    stream_hash = image_stream_by_service(params[:service_name])
    render json: release_version(stream_hash)
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    render json: upgrade_service_version(stream_hash)
  end
end
