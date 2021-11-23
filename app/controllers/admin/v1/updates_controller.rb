class Admin::V1::UpdatesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    stream_hash = image_stream_by_service(params[:service_name])
    render json: update_version(stream_hash)
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    render json: update_service_version(stream_hash)
  end
end
