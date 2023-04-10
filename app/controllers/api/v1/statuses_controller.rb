class Api::V1::StatusesController < ApplicationController
  include SystemServices
  include OsCommonHelper
  include ResponseHelper
  before_action :login
  before_action :setup_prefix, only: [:show]

  # def show
  #   services = service_config
  #   services = services.keys.map{|namespace| services[namespace] }.flatten
  #   services_statuses = []
  #   response = []
  #   services.compact.map do |service|
  #     status = service_status(service)
  #     next if status == {}
  #     services_statuses << status unless services_statuses.include?(status)
  #   end.compact
  #   services_statuses.map{|status| services_statuses.delete(status) if status.to_s == "{}"}
  #   services_statuses.compact.map do |service|
  #     common_name = service.keys.map do |name|
  #       "\"#{name}\".split('-')"
  #     end.join(" & ")
  #     common_service_name = eval(common_name).join("-")
  #     common_status = common_service_status(service)
  #     response << {"common_name"   => common_service_name,
  #                  "common_status" => common_service_status(service),
  #                  "common_service_installed" => common_service_installed(service),
  #                  "services"      => service}
  #   end

  #   success response
  # end

  def show
    namespaces = valid_namespaces(get_all_namespaces)
    services = namespaces.map { |namespace| common_service_name(namespace) }

    apps = parsed_services(namespaces)
    response = services.map do |service|
      service_apps = apps.select { |app| app["service"] == service }
      {
        "common_name" => service,
        "common_service_status" => common_service_status(service_apps),
        "common_service_installed" => common_service_installed(service_apps),
        "common_service_deleted" => common_service_deleted(service_apps),
        "services" => service_apps.map do |service_app|
          {
            service_app["name"] => {
              "service_installed" => service_app["service_installed"],
              "service_status"  => service_app["service_status"],
              "service_deleted" => service_app["service_deleted"]
            }
          }
        end
      }
    end

    success response
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

  def common_service_status(statuses)
    #state = []
    #statuses.keys.each do |service_name|
    #  service_status = statuses[service_name]["service_status"]
    #  state << service_status unless state.include?(service_status)
    #end
    state = statuses.map { |status| status["service_status"] }.uniq
    return state.first if state.count == 1
    return "Running" if state.include?("Running")
    return "Undefined" if state.include?("Undefined")
  end

  def common_service_installed(statuses)
    #state = statuses.keys.map do |service_name|
    #  statuses[service_name]["service_installed"]
    #end
    return "false" if statuses.map { |status| status["service_installed" ] }.include?("false")
    "true"
  end

  def common_service_deleted(statuses)
    return "false" if statuses.map { |status| status["service_deleted"] }.include?("false")
    "true"
  end

  def deployment_configs_list(namespaces)
    deployment_configs = []

    namespaces.each do |namespace|
      deployment_configs << get_deployment_configs(namespace)
    end

    deployment_configs.flatten
  end

  def parsed_services(namespaces)
    deployment_configs_list(namespaces).map do |dc|
      name = dc.dig("metadata", "name")
      service = dc.dig("metadata", "labels", "service")
      revision = dc.dig("status", "latestVersion")
      ns = dc.dig("metadata", "namespace")
      service_installed = image_stream_exists?(name, ns)
      service_deleted = service_installed ^ get_pvc(service)

      {
        "name" => name,
        "service" => service,
        "revision" => revision,
        "service_status" => get_replication_controller_status(name, revision, ns) || "Undefined",
        "service_installed" => service_installed,
        "service_deleted" => service_deleted
      }
    end
  end
end