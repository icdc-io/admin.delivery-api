class Api::V1::UpdatesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    render json: updated_version(stream_hash)
  end

  def create
    render json: update_service_version(stream_hash)
  end

private
  def stream_hash
    image_stream_by_service(params[:service_name])
  end
end
