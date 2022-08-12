class Api::V1::StatusesController < ApplicationController
  include SystemServices
  include OsCommonHelper
  include ResponseHelper
  before_action :login

  def show
    services = service_config
    services = services.keys.map{|namespace| services[namespace] }.flatten
    services_statuses = []
    response = []
    services.compact.map do |service|
      status = service_status(service)
      next if status == {}
      services_statuses << status unless services_statuses.include?(status)
    end.compact
    services_statuses.map{|status| services_statuses.delete(status) if status.to_s == "{}"}
    services_statuses.compact.map do |service|
      common_name = service.keys.map do |name|
        "\"#{name}\".split('-')"
      end.join(" & ")
      common_service_name = eval(common_name).join("-")
      common_status = common_service_status(service)
      response << {"common_name"   => common_service_name,
                   "common_status" => common_service_status(service),
                   "common_service_installed" => common_service_installed(service),
                   "services"      => service}
    end

    success response
  end



  private

  def common_service_status(statuses)
    state = []
    statuses.keys.each do |service_name|
      service_status = statuses[service_name]["service_status"]
      state << service_status unless state.include?(service_status)
    end
    return state.first if state.count == 1
    return "Running" if state.include?("Running")
    return "Undefined" if state.include?("Undefined")
  end

  def common_service_installed(statuses)
    state = statuses.keys.map do |service_name|
      statuses[service_name]["service_installed"]
    end
    return "false" if state.include?("false")
    "true"
  end
end