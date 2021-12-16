class Admin::V1::StatusesController < ApplicationController
  include SystemServices

  def show
    check_status(request.headers['x-icdc-location'], params[:service_name], params[:status_check])
  end
end
