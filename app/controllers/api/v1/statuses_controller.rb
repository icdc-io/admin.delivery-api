class Api::V1::StatusesController < ApplicationController
  include SystemServices
  include OsCommonHelper
  include ResponseHelper
  before_action :login
  before_action :setup_prefix, only: [:show]

  def show
    namespaces = valid_namespaces(get_all_namespaces)
    services = namespaces.map { |namespace| common_service_name(namespace) }

    dcs = parsed_dcs(namespaces)
    response = services.map do |service|
      service_dcs = dcs.select { |dc| dc["service"] == service }
      {
        "common_name" => service,
        "common_service_status" => common_service_status(service_dcs),
        "common_service_installed" => common_service_installed(service_dcs),
        "common_service_deleted" => common_service_deleted(service),
        "common_data_deleted" => common_data_deleted(service),
        "common_backup_deleted" => common_backup_deleted(service),
        "services" => service_dcs.map do |service_dc|
          {
            service_dc["name"] => {
              "service_installed" => service_dc["service_installed"],
              "service_status"  => service_dc["service_status"],
            }
          }
        end
      }
    end

    return success response
  end



  private

  def setup_prefix
    @prefix = ENV['NAMESPACE_PREFIX'] || 'cloud' 
  end

  def valid_namespaces(namespaces)
    namespaces.reject { |namespace| namespace unless namespace.start_with? @prefix }
  end

  def common_service_name(namespace)
    namespace.gsub("#{@prefix}-", '')
  end

  def common_service_status(dcs)
    state = dcs.map { |dc| dc["service_status"] }.uniq
    return state.first if state.count == 1
    return "Pending" if state.include?("Pending")
    return "Running" if state.include?("Running")
    return "Deleting" if state.include?("Deleting")
    return "Undefined" if state.include?("Undefined")
    return "Error" if state.include?("Error")
    return "Failed" if state.include?("Failed")
  end

  def common_service_installed(dcs)
    uniq_statuses = dcs.map { |dc| dc["service_installed"] }.uniq
    return false if (uniq_statuses.include?("false") || uniq_statuses.compact.empty?)
    true
  end

  def common_service_deleted(service)
    get_pvc(service).dig("items").empty?
  end

  def common_data_deleted(service)
    get_pvc_data(service).dig("items").empty?
  end

  def common_backup_deleted(service)
    get_pvc_backup(service).dig("items").empty?
  end

  def deployment_configs_list(namespaces)
    deployment_configs = []

    namespaces.each do |namespace|
      deployment_configs << get_deployment_configs(namespace)
    end

    deployment_configs.flatten
  end

  def parsed_dcs(namespaces)
    deployment_configs_list(namespaces).map do |dc|
      name = dc.dig("metadata", "name")
      service = dc.dig("metadata", "labels", "service")
      revision = dc.dig("status", "latestVersion")
      ns = dc.dig("metadata", "namespace")
      service_installed = image_stream_exists?(name, ns)
      service_status = revision > 0 ? get_replication_controller_status(name, revision, ns) : "Error"

      {
        "name" => name,
        "service" => service,
        "revision" => revision,
        "service_status" => service_status,
        "service_installed" => service_installed,
      }
    end
  end
end
