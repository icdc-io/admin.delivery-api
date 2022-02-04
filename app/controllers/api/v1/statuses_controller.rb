class Api::V1::StatusesController < ApplicationController
  include SystemServices
  before_action :login

  def show
    render json: check_status(get_location, params[:service_name], params[:status_check], params[:delete_persistent_data])
  end
end
