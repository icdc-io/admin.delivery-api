class Api::V1::StatusesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    render json: service_status(params[:service_name])# check_status(get_location, params[:service_name], params[:status_check], params[:delete_persistent_data])
  end
end
