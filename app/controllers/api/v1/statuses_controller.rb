class Api::V1::StatusesController < ApplicationController
  include SystemServices
  before_action :login
  before_action -> {
   $NAMESPACE = "icdc-#{params[:service_name]}"
  }

  def show
    render json: check_status(ENV['LOCATION_NAME'], params[:service_name], params[:status_check], params[:delete_persistent_data])
  end
end
