# frozen_string_literal: true

class Status
  attr_reader :prefix, :image_stream_list, :persistent_volume_claim_list, :deployment_config_list,
              :replication_controller_list

  def initialize
    @prefix = ENV.fetch('NAMESPACE_PREFIX', 'cloud')
    @image_stream_list = OkdClient.get_resource('apis/image.openshift.io/v1/imagestreams')['items']
    @persistent_volume_claim_list = OkdClient.get_resource('api/v1/persistentvolumeclaims')['items']
    @deployment_config_list = OkdClient.get_resource('apis/apps.openshift.io/v1/deploymentconfigs')['items']
    @replication_controller_list = OkdClient.get_resource('api/v1/replicationcontrollers')['items']
  end

  def get_info(namespace)
    service_name = namespace.gsub("#{prefix}-", '')
    find_image_stream = OKD::ImageStream.find_from_list(image_stream_list, service_name, namespace)
    {
      'common_name' => service_name,
      'common_service_status' => common_service_status(namespace, service_name),
      'common_service_installed' => find_image_stream ? true : false,
      'common_service_deleted' => common_service_deleted(namespace, service_name),
      'common_data_deleted' => common_data_deleted(namespace, service_name),
      'common_backup_deleted' => common_backup_deleted(namespace, service_name)
    }
  end

  private

  def common_service_status(namespace, service_name)
    service_dcs = OkdClient.select_service_dcs(deployment_config_list, namespace, service_name)
    states = service_apps_statuses(service_dcs).uniq
    return states.first if states.count == 1

    priority = %w[Pending Running Deleting Undefined Error Failed Complete]
    priority.each do |status|
      return status if states.include?(status)
    end
    nil
  end

  def service_apps_statuses(service_dcs)
    service_dcs.map do |dc|
      app_name = dc.dig('metadata', 'name')
      revision = dc.dig('status', 'latestVersion')
      namespace = dc.dig('metadata', 'namespace')
      if revision.positive?
        OkdClient.find_replication_controller(replication_controller_list, app_name, revision, namespace)
      else
        'Error'
      end
    end
  end

  def common_service_deleted(namespace, service_name)
    OkdClient.select_service_pvc(persistent_volume_claim_list, namespace, service_name).empty?
  end

  def common_data_deleted(namespace, service_name)
    OkdClient.select_service_pvc_by_type(persistent_volume_claim_list, namespace, service_name, 'data').empty?
  end

  def common_backup_deleted(namespace, service_name)
    OkdClient.select_service_pvc_by_type(persistent_volume_claim_list, namespace, service_name, 'backup').empty?
  end
end
