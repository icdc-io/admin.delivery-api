class Admin::V1::StatusesController < ApplicationController
  include SystemServices

  def show
    check_status(params[:zone], params[:service_name], params[:status_check])
  end
end
